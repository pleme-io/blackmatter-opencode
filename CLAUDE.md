# blackmatter-opencode — Claude Orientation

> **★★★ CSE / Knowable Construction.** This repo operates under **Constructive Substrate Engineering** — canonical specification at [`pleme-io/theory/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md`](https://github.com/pleme-io/theory/blob/main/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md). The Compounding Directive (operational rules: solve once, load-bearing fixes only, idiom-first, models stay current, direction beats velocity) is in the org-level pleme-io/CLAUDE.md ★★★ section. Read both before non-trivial changes.


One-sentence purpose: home-manager module that re-exports `pkgs.opencode`
with a Nord-themed, blackmatter-default config layered on top, integrated
with anvil for shared MCP servers and skill-helpers for cross-agent skill
redistribution.

## Classification

- **Archetype:** `blackmatter-component-hm-package`
- **Flake shape:** `substrate/lib/blackmatter-component-flake.nix`
- **Option namespace:** `blackmatter.components.opencode`
- **Systems:** `x86_64-linux`, `aarch64-linux`, `aarch64-darwin` (no
  `x86_64-darwin` — opencode isn't packaged for it upstream).

## Anvil Integration

OpenCode is a **self-serving** anvil agent (like Claude Code). It reads
`anvil.generatedServers` directly in its module and merges servers into
the `mcp` key of `opencode.json`. Registered as an anvil agent with
`configFormat = "opencode"` so that MCP server `agents` filtering works.

This means OpenCode automatically gets every MCP server defined in anvil
(github, codesearch, zoekt, kubernetes, atlassian, etc.) without any
duplication of server definitions or credential wrappers.

## Skills Redistribution

Skills are deployed to `~/.config/opencode/skills/{name}/SKILL.md` and
referenced via `skills.paths` in the opencode config. The same SKILL.md
definitions used by Claude Code are shared via the Nix module system:

```nix
blackmatter.components.opencode.skills.extraSkills = {
  context = "${inputs.blackmatter-claude}/skills/context/SKILL.md";
  service = "${inputs.blackmatter-claude}/skills/service/SKILL.md";
  build   = "${inputs.blackmatter-claude}/skills/build/SKILL.md";
  tend    = "${inputs.blackmatter-claude}/skills/tend/SKILL.md";
};
```

Any agent can consume the same skill definitions by pointing to the source
files. The `skill-helpers.nix` `basePath` parameter controls deployment
location per agent (e.g., `.claude/skills/` vs `.config/opencode/skills/`).

## Where to look

| Intent | File |
|--------|------|
| HM option schema + config generation | `module/default.nix` |
| Typed option definitions | `module/opencode-options.nix` |
| Nord palette source-of-truth | `module/themes/nord/colors.nix` |
| Blackmatter opencode theme JSON | `module/themes/nord/blackmatter.json` |
| Flake surface + bespoke checks | `flake.nix` |

## Custom checks (preserved via `extraChecks`)

- `module-defaults` — default option values are sane
- `theme-colors` — every Nord palette key is present
- `theme-json` — generated theme JSON is well-formed with all 51 theme keys
- `module-enable` — with `enable = true`, config renders into `home.file`
- `package-build` — `pkgs.opencode` binary resolves

## What NOT to do

- Don't inline upstream opencode changes — this repo wraps, doesn't fork.
- Don't hardcode user preferences (model, API keys). Those are consumer inputs.
- Don't duplicate anvil MCP server definitions — consume `anvil.generatedServers`.
- Don't duplicate skill content — reference source files via `extraSkills`.
