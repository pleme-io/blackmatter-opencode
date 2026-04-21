{
  description = "Blackmatter OpenCode — AI coding agent with Nord theme and blackmatter defaults";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    substrate = {
      url = "github:pleme-io/substrate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, substrate, ... }:
    (import "${substrate}/lib/blackmatter-component-flake.nix") {
      inherit self nixpkgs;
      name = "blackmatter-opencode";
      description = "AI coding agent wrapper — re-exports pkgs.opencode with declarative config";

      # opencode is not packaged for x86_64-darwin upstream.
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      modules.homeManager = ./module;
      autoEvalChecks = true;

      # Re-export opencode from nixpkgs (not a wrapper — the module handles config).
      package = pkgs: pkgs.opencode;

      # Preserve opencode's bespoke theme/validation checks alongside the
      # generic eval-hm-module smoke test contributed by mkBlackmatterFlake.
      extraChecks = pkgs: let
        lib = nixpkgs.lib;

        moduleEval = lib.evalModules {
          modules = [
            ./module
            ({ lib, ... }: {
              config._module.args = { inherit pkgs; };
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

        enabledEval = lib.evalModules {
          modules = [
            ./module
            ({ lib, ... }: {
              config._module.args = { inherit pkgs; };
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

        colors = import ./module/themes/nord/colors.nix;
        themeJson = builtins.fromJSON (builtins.readFile ./module/themes/nord/blackmatter.json);
        generatedConfig = builtins.fromJSON
          enabledEval.config.home.file.".config/opencode/opencode.json".text;
      in {
        module-defaults = pkgs.runCommand "opencode-module-defaults" {} ''
          echo "Default theme: ${moduleEval.config.blackmatter.components.opencode.theme.name}"
          echo "Default autoupdate: ${builtins.toJSON moduleEval.config.blackmatter.components.opencode.autoupdate}"
          echo "Enable default: ${builtins.toJSON moduleEval.config.blackmatter.components.opencode.enable}"
          touch $out
        '';

        theme-colors = pkgs.runCommand "opencode-theme-colors" {} ''
          echo "polar.night0 = ${colors.polar.night0}"
          echo "snow.storm0 = ${colors.snow.storm0}"
          echo "frost.frost0 = ${colors.frost.frost0}"
          echo "aurora.red = ${colors.aurora.red}"
          touch $out
        '';

        theme-json = pkgs.runCommand "opencode-theme-json" {} ''
          echo "Schema: ${themeJson."$schema"}"
          echo "defs.nord0 = ${themeJson.defs.nord0}"
          echo "theme.primary.dark = ${themeJson.theme.primary.dark}"
          echo "Theme keys: ${builtins.toJSON (builtins.length (builtins.attrNames themeJson.theme))}"
          touch $out
        '';

        module-enable = pkgs.runCommand "opencode-module-enable" {} ''
          echo "Enable = ${builtins.toJSON enabledEval.config.blackmatter.components.opencode.enable}"
          echo "Config theme: ${generatedConfig.theme}"
          echo "Config autoupdate: ${builtins.toJSON generatedConfig.autoupdate}"
          echo "Theme file deployed: ${builtins.toJSON (builtins.hasAttr ".config/opencode/themes/blackmatter.json" enabledEval.config.home.file)}"
          echo "Package count: ${builtins.toJSON (builtins.length enabledEval.config.home.packages)}"
          touch $out
        '';

        package-build = pkgs.runCommand "opencode-package-build" {} ''
          test -x ${pkgs.opencode}/bin/opencode
          echo "opencode version: ${pkgs.opencode.version}"
          touch $out
        '';
      };
    };
}
