# module/default.nix
# OpenCode AI coding agent - blackmatter distribution with Nord theme
#
# Integrates with blackmatter-anvil for shared MCP server definitions
# and blackmatter skill-helpers for cross-agent skill redistribution.
#
# Anvil integration:
#   anvil.generatedServers → merged into opencode mcp config
#   (self-serving pattern — same as blackmatter-claude)
#
# Skills:
#   Deployed to ~/.config/opencode/skills/{name}/SKILL.md
#   Referenced via skills.paths in opencode.json
#   Same skill definitions shared across all agents via Nix module system
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

  # ── Conditional attribute helpers ──────────────────────────────────
  optAttr = name: value: optionalAttrs (value != null) { ${name} = value; };
  optList = name: value: optionalAttrs (value != []) { ${name} = value; };
  optNested = name: value: optionalAttrs (value != {}) { ${name} = value; };

  # Recursively strip null values from attrsets
  stripNulls = value:
    if builtins.isAttrs value then
      lib.filterAttrs (_: v: v != null) (builtins.mapAttrs (_: stripNulls) value)
    else if builtins.isList value then
      map stripNulls value
    else
      value;

  # ── Anvil MCP server integration ────────────────────────────────
  # Read shared servers from anvil (same pattern as blackmatter-claude).
  # Anvil generates wrapper scripts with credential resolution, so we
  # get the same servers as Claude/Cursor without duplicating definitions.
  # Uses optionalAttrs-style access to gracefully handle the case where
  # the anvil module is not imported (standalone eval, testing, etc.).
  anvilConfig =
    if builtins.hasAttr "anvil" (config.blackmatter.components or {})
    then config.blackmatter.components.anvil
    else { enable = false; generatedServers = {}; };
  anvilServers =
    if anvilConfig.enable
    then anvilConfig.generatedServers
    else {};

  # Merge anvil servers with user-defined MCP options. Anvil provides
  # the baseline (resolved wrappers, credentials). User-defined mcp
  # entries override anvil on name collision (for opencode-specific tuning).
  mcpSources = anvilServers // (mapAttrs (_name: srv: {
    inherit (srv) type command args env;
    enabled = srv.enabled or true;
  }) cfg.mcp);

  # Convert merged MCP attrs to JSON-ready format.
  # Access optional fields with `or` defaults because anvil-sourced servers
  # (from substrate's mkResolvedServers) only carry {type, command, args}
  # — env/enabled are absent there.
  mcpJson = mapAttrs (_name: srv: let
    sArgs = srv.args or [];
    sEnv = srv.env or {};
    sEnabled = srv.enabled or true;
  in
    { inherit (srv) type command; }
    // optionalAttrs (sArgs != []) { args = sArgs; }
    // optionalAttrs (sEnv != {}) { env = sEnv; }
    // optionalAttrs (!sEnabled) { enabled = false; }
  ) mcpSources;

  # ── Skills deployment ──────────────────────────────────────────
  # Skills are deployed to ~/.config/opencode/skills/{name}/SKILL.md
  # and referenced via skills.paths in the config JSON.
  # This follows the same pattern as Claude but with a different basePath,
  # enabling cross-agent skill redistribution through the Nix module system.
  skillsBasePath = ".config/opencode/skills";
  allSkillFiles = cfg.skills.extraSkills;

  skillsHomeFiles = lib.mapAttrs' (name: path:
    lib.nameValuePair "${skillsBasePath}/${name}/SKILL.md" {
      source = path;
    }
  ) allSkillFiles;

  # The skills.paths config entry — include the deployed skills directory
  # plus any user-specified additional paths.
  skillsPaths =
    (optional (allSkillFiles != {}) "${config.home.homeDirectory}/${skillsBasePath}")
    ++ cfg.skills.paths;

  # Build skills config for opencode.json
  skillsConfig =
    (optList "paths" skillsPaths)
    // (optList "urls" cfg.skills.urls);

  # ── Convert typed provider attrs to JSON-ready format ────────────
  providerJson = mapAttrs (_name: prov:
    let
      typed = filterAttrs (_: v: v != null) {
        inherit (prov) apiKey apiKeyEnv baseUrl;
      } // optionalAttrs prov.disabled { disabled = true; };
      extra = removeAttrs prov [ "apiKey" "apiKeyEnv" "baseUrl" "disabled" "_module" ];
    in typed // extra
  ) cfg.provider;

  # ── Convert typed tools attrs to JSON-ready format ──────────────
  toolsJson = mapAttrs (_name: tool:
    { inherit (tool) enabled; }
  ) cfg.tools;

  # ── Convert typed permission to JSON-ready format ───────────────
  permissionJson =
    optionalAttrs (cfg.permission.default != "ask") {
      default = cfg.permission.default;
    }
    // optionalAttrs (cfg.permission.tools != {}) {
      tools = cfg.permission.tools;
    };

  # ── Convert typed TUI to JSON-ready format ──────────────────────
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

  # ── Convert mode/agent config to JSON-ready format ──────────────
  modeJson = mapAttrs (_name: agent:
    stripNulls (
      optAttr "model" agent.model
      // optAttr "variant" agent.variant
      // optAttr "temperature" agent.temperature
      // optAttr "top_p" agent.top_p
      // optAttr "prompt" agent.prompt
      // optAttr "description" agent.description
      // optAttr "mode" agent.mode
      // optAttr "steps" agent.steps
      // optionalAttrs agent.disable { disable = true; }
      // optionalAttrs agent.hidden { hidden = true; }
      // (removeAttrs agent [
        "model" "variant" "temperature" "top_p" "prompt"
        "description" "mode" "steps" "disable" "hidden" "_module"
      ])
    )
  ) cfg.mode;

  # ── Build the opencode.json config ──────────────────────────────
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
  } // optionalAttrs (skillsConfig != {}) {
    skills = skillsConfig;
  } // optionalAttrs (modeJson != {}) {
    mode = modeJson;
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

    inherit (opencodeOpts) provider mcp tools keybinds skills mode;

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

    # Write global opencode config (includes anvil MCP servers)
    {
      home.file.".config/opencode/opencode.json".text = configJson;
    }

    # Write blackmatter theme (custom Nord-enhanced)
    (mkIf (!cfg.theme.useBuiltinNord) {
      home.file.".config/opencode/themes/blackmatter.json".source =
        ./themes/nord/blackmatter.json;
    })

    # Deploy skills to ~/.config/opencode/skills/
    (mkIf (cfg.skills.enable && allSkillFiles != {}) {
      home.file = skillsHomeFiles;
    })
  ]);
}
