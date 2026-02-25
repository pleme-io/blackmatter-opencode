# module/default.nix
# OpenCode AI coding agent - blackmatter distribution with Nord theme
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.opencode;

  # Import shared Nord palette
  colors = import ./themes/nord/colors.nix;

  # Map shared colors to numbered Nord names
  nord = {
    nord0 = colors.polar.night0;
    nord1 = colors.polar.night1;
    nord2 = colors.polar.night2;
    nord3 = colors.polar.night3;
    nord4 = colors.snow.storm0;
    nord5 = colors.snow.storm1;
    nord6 = colors.snow.storm2;
    nord7 = colors.frost.frost0;
    nord8 = colors.frost.frost1;
    nord9 = colors.frost.frost2;
    nord10 = colors.frost.frost3;
    nord11 = colors.aurora.red;
    nord12 = colors.aurora.orange;
    nord13 = colors.aurora.yellow;
    nord14 = colors.aurora.green;
    nord15 = colors.aurora.purple;
  };

  # Build the opencode.json config
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    theme = cfg.theme.name;
    autoupdate = cfg.autoupdate;
  } // optionalAttrs (cfg.model != null) {
    model = cfg.model;
  } // optionalAttrs (cfg.smallModel != null) {
    small_model = cfg.smallModel;
  } // optionalAttrs (cfg.provider != {}) {
    provider = cfg.provider;
  } // optionalAttrs (cfg.disabledProviders != []) {
    disabled_providers = cfg.disabledProviders;
  } // optionalAttrs (cfg.enabledProviders != []) {
    enabled_providers = cfg.enabledProviders;
  } // optionalAttrs (cfg.keybinds != {}) {
    keybinds = cfg.keybinds;
  } // optionalAttrs (cfg.mcp != {}) {
    mcp = cfg.mcp;
  } // optionalAttrs (cfg.tools != {}) {
    tools = cfg.tools;
  } // optionalAttrs (cfg.permission != {}) {
    permission = cfg.permission;
  } // optionalAttrs (cfg.tui != {}) {
    tui = cfg.tui;
  } // optionalAttrs (cfg.instructions != []) {
    instructions = cfg.instructions;
  } // cfg.extraConfig;

  configJson = builtins.toJSON opencodeConfig;
in {
  options.blackmatter.components.opencode = {
    enable = mkEnableOption "OpenCode AI coding agent";

    theme = {
      name = mkOption {
        type = types.str;
        default = "blackmatter";
        description = "Theme name (must match a file in themes directory)";
      };

      useBuiltinNord = mkOption {
        type = types.bool;
        default = false;
        description = "Use opencode's built-in Nord theme instead of blackmatter custom";
      };
    };

    model = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default model (e.g. anthropic/claude-sonnet-4-5)";
      example = "anthropic/claude-sonnet-4-5";
    };

    smallModel = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Small model for quick tasks (e.g. anthropic/claude-haiku-4-5)";
      example = "anthropic/claude-haiku-4-5";
    };

    provider = mkOption {
      type = types.attrs;
      default = {};
      description = "Provider configuration overrides";
    };

    disabledProviders = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Providers to disable";
    };

    enabledProviders = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Providers to enable (empty = all enabled)";
    };

    keybinds = mkOption {
      type = types.attrs;
      default = {};
      description = "Keybinding overrides";
      example = {
        leader = "ctrl+x";
        app_exit = "ctrl+c,ctrl+d,<leader>q";
      };
    };

    mcp = mkOption {
      type = types.attrs;
      default = {};
      description = "MCP server configuration";
    };

    tools = mkOption {
      type = types.attrs;
      default = {};
      description = "Tool enable/disable overrides";
    };

    permission = mkOption {
      type = types.attrs;
      default = {};
      description = "Permission settings for tools";
    };

    tui = mkOption {
      type = types.attrs;
      default = {};
      description = "TUI display settings";
    };

    instructions = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Custom instruction files to include";
    };

    autoupdate = mkOption {
      type = types.either types.bool (types.enum ["notify"]);
      default = false;
      description = "Auto-update behavior (true, false, or 'notify')";
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional opencode.json settings merged at top level";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Install opencode package
    {
      home.packages = [ pkgs.opencode ];
    }

    # Write global opencode config
    {
      home.file.".config/opencode/opencode.json".text = configJson;
    }

    # Write blackmatter theme (custom Nord-enhanced)
    (mkIf (!cfg.theme.useBuiltinNord) {
      home.file.".config/opencode/themes/blackmatter.json".source =
        ./themes/nord/blackmatter.json;
    })
  ]);
}
