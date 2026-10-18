# aur-packages

PKGBUILDs for the AUR packages maintained by [anjanaya](https://aur.archlinux.org/account/anjanaya). One directory per package, directory name == `pkgbase`.

## How it works

- **This repo is the source of truth.** The AUR is never polled; it is cloned only to push a real change.
- `.github/workflows/update.yml` runs daily (05:17 UTC) and on manual dispatch: [aur-checker](https://codeberg.org/arch-linux-aur/aur-checker) checks upstream (GitHub/Codeberg/npm), bumps `pkgver`, runs `updpkgsums`, regenerates `.SRCINFO`, test-builds with `makepkg -sf`. Packages whose build fails are reverted.
- The build job holds no secrets and no sudo (upstream build code runs there). The separate publish job has the AUR key; it re-derives every bump from `main` and publishes only if that matches what was test-built, via `scripts/publish-aur.sh` (fresh clone, copy tracked files, commit, push; never force), then commits here as the bot. Any failed build, rejected artifact, or failed push turns the run red.
- Pushing a PKGBUILD change to `main` yourself triggers the same publish step for the changed dirs. **Never push to AUR from a local machine.**

Secrets: `AUR_SSH_KEY` (dedicated ed25519 key registered on the AUR account), `AUR_COMMIT_NAME`, `AUR_COMMIT_EMAIL` (identity for AUR commits). The built-in `GITHUB_TOKEN` covers upstream API rate limits.

## Packages

| Package | AUR | Upstream |
|---------|-----|----------|
| agent-browser | [aur](https://aur.archlinux.org/packages/agent-browser) | https://github.com/vercel-labs/agent-browser |
| bleamd-git | [aur](https://aur.archlinux.org/packages/bleamd-git) | https://github.com/guttermonk/bleamd |
| clangen-bin | [aur](https://aur.archlinux.org/packages/clangen-bin) | https://clangen.io |
| codeburn-desktop-bin | [aur](https://aur.archlinux.org/packages/codeburn-desktop-bin) | https://github.com/getagentseal/codeburn |
| data-peek-bin | [aur](https://aur.archlinux.org/packages/data-peek-bin) | https://www.datapeek.dev |
| enject | [aur](https://aur.archlinux.org/packages/enject) | https://github.com/GreatScott/enject |
| epinio-bin | [aur](https://aur.archlinux.org/packages/epinio-bin) | https://epinio.io |
| eugene-bin | [aur](https://aur.archlinux.org/packages/eugene-bin) | https://github.com/kaaveland/eugene |
| forgejo-mcp-bin | [aur](https://aur.archlinux.org/packages/forgejo-mcp-bin) | https://git.b4mad.industries/agentic-forges/forgejo-mcp |
| glm-bin | [aur](https://aur.archlinux.org/packages/glm-bin) | https://github.com/xqsit94/glm |
| grafanactl-bin | [aur](https://aur.archlinux.org/packages/grafanactl-bin) | https://github.com/grafana/grafanactl |
| kotlin-toolchain | [aur](https://aur.archlinux.org/packages/kotlin-toolchain) | https://kotlin-toolchain.org |
| mcp-cli-git | [aur](https://aur.archlinux.org/packages/mcp-cli-git) | https://github.com/philschmid/mcp-cli |
| open-pencil-bin | [aur](https://aur.archlinux.org/packages/open-pencil-bin) | https://github.com/open-pencil/open-pencil |
| pgrok-bin | [aur](https://aur.archlinux.org/packages/pgrok-bin) | https://github.com/pgrok/pgrok |
| pgrokd-bin | [aur](https://aur.archlinux.org/packages/pgrokd-bin) | https://github.com/pgrok/pgrok |
| pipenet | [aur](https://aur.archlinux.org/packages/pipenet) | https://github.com/punkpeye/pipenet |
| playwright-cli | [aur](https://aur.archlinux.org/packages/playwright-cli) | https://playwright.dev/ |
| qodana-cli-bin | [aur](https://aur.archlinux.org/packages/qodana-cli-bin) | https://github.com/JetBrains/qodana-cli |
| ralph-tui | [aur](https://aur.archlinux.org/packages/ralph-tui) | https://github.com/subsy/ralph-tui |
| redpanda-bin | [aur](https://aur.archlinux.org/packages/redpanda-bin) | https://github.com/redpanda-data/redpanda |
| rpg | [aur](https://aur.archlinux.org/packages/rpg) | https://github.com/NikolayS/rpg |
| squawk-bin | [aur](https://aur.archlinux.org/packages/squawk-bin) | https://squawkhq.com/ |
| ttl-bin | [aur](https://aur.archlinux.org/packages/ttl-bin) | https://github.com/lance0/ttl |
| turso-cli | [aur](https://aur.archlinux.org/packages/turso-cli) | https://github.com/tursodatabase/turso-cli |
| turso-cli-bin | [aur](https://aur.archlinux.org/packages/turso-cli-bin) | https://github.com/tursodatabase/turso-cli |
| varlock-bin | [aur](https://aur.archlinux.org/packages/varlock-bin) | https://varlock.dev |
| velo-bin | [aur](https://aur.archlinux.org/packages/velo-bin) | https://github.com/avihaymenahem/velo |
| vex-tui-bin | [aur](https://aur.archlinux.org/packages/vex-tui-bin) | https://github.com/CodeOne45/vex-tui |

Not auto-updated (aur-checker skips them): `bleamd-git`, `mcp-cli-git` (VCS packages), `forgejo-mcp-bin` (self-hosted Forgejo source, not recognised by aur-checker 0.6.0).
