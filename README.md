# blackmatter-opencode

Home-manager module for the OpenCode AI coding agent with Nord theme.

## Overview

Declaratively configures the OpenCode AI coding agent via home-manager. Generates `~/.config/opencode/opencode.json` and deploys a custom Nord-based "blackmatter" theme. Supports model selection, provider configuration, and auto-update control.

## Flake Outputs

- `packages.<system>.opencode` -- OpenCode binary (re-exported from nixpkgs)
- `homeManagerModules.default` -- home-manager module at `blackmatter.components.opencode`

## Usage

```nix
{
  inputs.blackmatter-opencode.url = "github:pleme-io/blackmatter-opencode";
}
```

```nix
blackmatter.components.opencode = {
  enable = true;
  theme.name = "blackmatter";
  autoupdate = false;
};
```

## Structure

- `module/` -- home-manager module + generated config
- `module/themes/nord/` -- Nord color palette + blackmatter.json theme
