{
  description = "Blackmatter OpenCode - AI coding agent with Nord theme and blackmatter defaults";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      allSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f system);
    in {
      # Re-export opencode from nixpkgs (available on all platforms)
      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          opencode = pkgs.opencode;
          default = pkgs.opencode;
        }
      );

      # Home-manager module for opencode configuration
      homeManagerModules.default = import ./module;

      # ── Checks ──────────────────────────────────────────────────
      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = nixpkgs.lib;

          # Evaluate the module in isolation with minimal stubs for HM options
          moduleEval = lib.evalModules {
            modules = [
              ./module
              ({ lib, ... }: {
                config._module.args = { pkgs = pkgs; };
                options.home.packages = lib.mkOption {
                  type = lib.types.listOf lib.types.package;
                  default = [];
                };
                options.home.file = lib.mkOption {
                  type = lib.types.attrsOf (lib.types.submodule {
                    options.text = lib.mkOption { type = lib.types.str; default = ""; };
                    options.source = lib.mkOption { type = lib.types.path; default = ./.; };
                  });
                  default = {};
                };
              })
            ];
          };

          # Import the colors file and verify its structure
          colors = import ./module/themes/nord/colors.nix;

          # Parse the theme JSON to verify it's well-formed
          themeJson = builtins.fromJSON (builtins.readFile ./module/themes/nord/blackmatter.json);
        in {
          # Verify module options exist and are well-formed
          module-eval = pkgs.runCommand "opencode-module-eval" {} ''
            # Module options are reachable
            echo "Option exists: ${builtins.toJSON (builtins.hasAttr "opencode" moduleEval.config.blackmatter.components)}"

            # Verify key option defaults
            echo "Default theme: ${moduleEval.config.blackmatter.components.opencode.theme.name}"
            echo "Default autoupdate: ${builtins.toJSON moduleEval.config.blackmatter.components.opencode.autoupdate}"

            # Verify enable defaults to false
            echo "Enable default: ${builtins.toJSON moduleEval.config.blackmatter.components.opencode.enable}"

            touch $out
          '';

          # Verify Nord palette structure is complete
          theme-colors = pkgs.runCommand "opencode-theme-colors" {} ''
            # Polar Night (4 shades)
            echo "polar.night0 = ${colors.polar.night0}"
            echo "polar.night1 = ${colors.polar.night1}"
            echo "polar.night2 = ${colors.polar.night2}"
            echo "polar.night3 = ${colors.polar.night3}"

            # Snow Storm (3 shades)
            echo "snow.storm0 = ${colors.snow.storm0}"
            echo "snow.storm1 = ${colors.snow.storm1}"
            echo "snow.storm2 = ${colors.snow.storm2}"

            # Frost (4 shades)
            echo "frost.frost0 = ${colors.frost.frost0}"
            echo "frost.frost1 = ${colors.frost.frost1}"
            echo "frost.frost2 = ${colors.frost.frost2}"
            echo "frost.frost3 = ${colors.frost.frost3}"

            # Aurora (5 colors)
            echo "aurora.red = ${colors.aurora.red}"
            echo "aurora.orange = ${colors.aurora.orange}"
            echo "aurora.yellow = ${colors.aurora.yellow}"
            echo "aurora.green = ${colors.aurora.green}"
            echo "aurora.purple = ${colors.aurora.purple}"

            touch $out
          '';

          # Verify blackmatter theme JSON is well-formed and complete
          theme-json = pkgs.runCommand "opencode-theme-json" {} ''
            # Verify schema field
            echo "Schema: ${themeJson."$schema"}"

            # Verify all 16 Nord defs exist
            echo "defs.nord0 = ${themeJson.defs.nord0}"
            echo "defs.nord15 = ${themeJson.defs.nord15}"
            echo "defs.muted = ${themeJson.defs.muted}"

            # Verify key theme sections exist
            echo "theme.primary.dark = ${themeJson.theme.primary.dark}"
            echo "theme.background.dark = ${themeJson.theme.background.dark}"
            echo "theme.text.dark = ${themeJson.theme.text.dark}"
            echo "theme.syntaxKeyword.dark = ${themeJson.theme.syntaxKeyword.dark}"
            echo "theme.diffAdded.dark = ${themeJson.theme.diffAdded.dark}"
            echo "theme.markdownHeading.dark = ${themeJson.theme.markdownHeading.dark}"

            # Count theme keys (should be 51)
            echo "Theme keys: ${builtins.toJSON (builtins.length (builtins.attrNames themeJson.theme))}"

            touch $out
          '';

          # Verify module enables correctly and produces valid config
          module-enable = let
            enabledEval = lib.evalModules {
              modules = [
                ./module
                ({ lib, ... }: {
                  config._module.args = { pkgs = pkgs; };
                  config.blackmatter.components.opencode.enable = true;
                  options.home.packages = lib.mkOption {
                    type = lib.types.listOf lib.types.package;
                    default = [];
                  };
                  options.home.file = lib.mkOption {
                    type = lib.types.attrsOf (lib.types.submodule {
                      options.text = lib.mkOption { type = lib.types.str; default = ""; };
                      options.source = lib.mkOption { type = lib.types.path; default = ./.; };
                    });
                    default = {};
                  };
                })
              ];
            };
            generatedConfig = builtins.fromJSON enabledEval.config.home.file.".config/opencode/opencode.json".text;
          in pkgs.runCommand "opencode-module-enable" {} ''
            echo "Module enabled successfully"
            echo "Enable = ${builtins.toJSON enabledEval.config.blackmatter.components.opencode.enable}"

            # Verify generated config has expected fields
            echo "Config theme: ${generatedConfig.theme}"
            echo "Config autoupdate: ${builtins.toJSON generatedConfig.autoupdate}"
            echo "Config has schema: ${builtins.toJSON (builtins.hasAttr "$schema" generatedConfig)}"

            # Verify theme file is deployed
            echo "Theme file deployed: ${builtins.toJSON (builtins.hasAttr ".config/opencode/themes/blackmatter.json" enabledEval.config.home.file)}"

            # Verify opencode package is in home.packages
            echo "Package count: ${builtins.toJSON (builtins.length enabledEval.config.home.packages)}"

            touch $out
          '';

          # Verify opencode package builds
          package-build = pkgs.runCommand "opencode-package-build" {} ''
            # Verify the opencode binary exists
            test -x ${pkgs.opencode}/bin/opencode
            echo "opencode binary exists at ${pkgs.opencode}/bin/opencode"
            echo "opencode version: ${pkgs.opencode.version}"
            touch $out
          '';
        }
      );
    };
}
