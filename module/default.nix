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
  opencodeOpts = import ./opencode-options.nix { inherit lib; };

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

  # Convert typed provider attrs to JSON-ready format (strip nulls)
  providerJson = mapAttrs (_name: prov:
    filterAttrs (_: v: v != null) {
      inherit (prov) apiKey apiKeyEnv baseUrl;
    } // optionalAttrs prov.disabled { disabled = true; }
  ) cfg.provider;

  # Convert typed MCP attrs to JSON-ready format
  mcpJson = mapAttrs (_name: srv:
    { inherit (srv) type command; }
    // optionalAttrs (srv.args != []) { inherit (srv) args; }
    // optionalAttrs (srv.env != {}) { inherit (srv) env; }
    // optionalAttrs (!srv.enabled) { enabled = false; }
  ) cfg.mcp;

  # Convert typed tools attrs to JSON-ready format
  toolsJson = mapAttrs (_name: tool:
    { inherit (tool) enabled; }
  ) cfg.tools;

  # Convert typed permission to JSON-ready format
  permissionJson =
    optionalAttrs (cfg.permission.default != "ask") {
      default = cfg.permission.default;
    }
    // optionalAttrs (cfg.permission.tools != {}) {
      tools = cfg.permission.tools;
    };

  # Convert typed TUI to JSON-ready format
  tuiJson =
    optionalAttrs (cfg.tui.showToolCalls != true) {
      show_tool_calls = cfg.tui.showToolCalls;
    }
    // optionalAttrs cfg.tui.showTokenUsage {
      show_token_usage = true;
    }
    // optionalAttrs (cfg.tui.theme != null) {
      theme = cfg.tui.theme;
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
  } // optionalAttrs (providerJson != {}) {
    provider = providerJson;
  } // optionalAttrs (cfg.disabledProviders != []) {
    disabled_providers = cfg.disabledProviders;
  } // optionalAttrs (cfg.enabledProviders != []) {
    enabled_providers = cfg.enabledProviders;
  } // optionalAttrs (cfg.keybinds != {}) {
    keybinds = cfg.keybinds;
  } // optionalAttrs (mcpJson != {}) {
    mcp = mcpJson;
  } // optionalAttrs (toolsJson != {}) {
    tools = toolsJson;
  } // optionalAttrs (permissionJson != {}) {
    permission = permissionJson;
  } // optionalAttrs (tuiJson != {}) {
    tui = tuiJson;
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

    inherit (opencodeOpts) provider mcp tools keybinds;

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

    permission = opencodeOpts.permission;

    tui = opencodeOpts.tui;

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
