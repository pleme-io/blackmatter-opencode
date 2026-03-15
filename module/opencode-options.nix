# OpenCode configuration options — typed schema matching opencode.json
#
# Every option maps to an OpenCode config key. Types enforced by Nix module system.
# Source: https://opencode.ai/config.json
{ lib, ... }:
with lib;
{
  # ── provider.* ─────────────────────────────────────────────────
  provider = mkOption {
    type = types.attrsOf (types.submodule {
      freeformType = types.attrs;
      options = {
        apiKey = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "API key for this provider.";
        };
        apiKeyEnv = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Env var name containing the API key.";
        };
        baseUrl = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Custom base URL for the provider API.";
        };
        disabled = mkOption {
          type = types.bool;
          default = false;
          description = "Disable this provider.";
        };
      };
    });
    default = {};
    description = "Provider configuration overrides. Accepts additional provider-specific fields (npm, name, options, models).";
  };

  # ── mcp.* ──────────────────────────────────────────────────────
  mcp = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        type = mkOption {
          type = types.enum [ "stdio" "sse" ];
          default = "stdio";
          description = "MCP server transport type.";
        };
        command = mkOption {
          type = types.str;
          description = "MCP server command.";
        };
        args = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Arguments to pass to the MCP server command.";
        };
        env = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Environment variables for the MCP server.";
        };
        enabled = mkOption {
          type = types.bool;
          default = true;
          description = "Enable/disable this MCP server.";
        };
      };
    });
    default = {};
    description = "MCP server definitions.";
  };

  # ── tools.* ────────────────────────────────────────────────────
  tools = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        enabled = mkOption {
          type = types.bool;
          default = true;
          description = "Enable/disable this tool.";
        };
      };
    });
    default = {};
    description = "Tool enable/disable overrides.";
  };

  # ── permission.* ───────────────────────────────────────────────
  permission = {
    default = mkOption {
      type = types.enum [ "allow" "ask" "deny" ];
      default = "ask";
      description = "Default permission for tool operations.";
    };
    tools = mkOption {
      type = types.attrsOf (types.enum [ "allow" "ask" "deny" ]);
      default = {};
      description = "Per-tool permission overrides.";
    };
  };

  # ── tui.* ──────────────────────────────────────────────────────
  tui = {
    showToolCalls = mkOption {
      type = types.bool;
      default = true;
      description = "Show tool call details in TUI.";
    };
    showTokenUsage = mkOption {
      type = types.bool;
      default = false;
      description = "Show token usage statistics.";
    };
    theme = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "TUI theme name.";
    };
  };

  # ── keybinds.* ─────────────────────────────────────────────────
  keybinds = mkOption {
    type = types.attrsOf types.str;
    default = {};
    description = "Keybinding overrides. Key = action, value = key combo.";
    example = {
      leader = "ctrl+x";
      app_exit = "ctrl+c,ctrl+d,<leader>q";
    };
  };
}
