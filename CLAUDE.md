# blackmatter-opencode — Claude Orientation

One-sentence purpose: home-manager module that re-exports `pkgs.opencode`
with a Nord-themed, blackmatter-default config layered on top.

## Classification

- **Archetype:** `blackmatter-component-hm-package`
- **Flake shape:** `substrate/lib/blackmatter-component-flake.nix`
- **Option namespace:** `blackmatter.components.opencode`
- **Systems:** `x86_64-linux`, `aarch64-linux`, `aarch64-darwin` (no
  `x86_64-darwin` — opencode isn't packaged for it upstream).

## Where to look

| Intent | File |
|--------|------|
| HM option schema + config generation | `module/default.nix` |
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
