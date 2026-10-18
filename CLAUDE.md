# AUR Packages Monorepo

You are assisting an Arch Linux AUR package maintainer.

## Maintainer Info

- **Name:** Guru
- **Email:** anjanaya@gmail.com
- **AUR username:** anjanaya
- **AUR profile:** https://aur.archlinux.org/account/anjanaya
- **Maintainer line:** `# Maintainer: Guru <anjanaya@gmail.com>`
- When adopting a package, add the previous maintainer as `# Contributor:`

## Repo Structure

**One git repo** (`github.com/comdotlinux/aur-packages`, remote `origin`). One directory per package, **directory name == `pkgbase`** (checked by `scripts/publish-aur.sh`). Package dirs are plain folders, not git repos and not submodules. Each contains `PKGBUILD`, `.SRCINFO`, optional `*.install` / local source files (e.g. `clangen-bin/clangen.desktop`), and a `.gitignore` that whitelists exactly those files. Everything git-tracked in a package dir is what gets published to AUR; files removed here are removed on AUR (mirror).

Packages on AUR (29): see `README.md` table (generated from `.SRCINFO`). `mcp-cli-bin` on AUR belongs to another maintainer (dbirks); never add it here.

## How changes reach AUR

`.github/workflows/update.yml` is the only thing that talks to AUR:

- **Daily cron / `gh workflow run update.yml [-f packages="a b"]`:** job `update` (no secrets, no sudo, read-only token) runs `aur-checker update --yes` (upstream check -> pkgver bump -> `updpkgsums` -> `.SRCINFO` -> `makepkg -sf`) and uploads the PKGBUILD/.SRCINFO of packages that printed `Successfully updated` as an artifact. Job `publish` (holds the secrets) treats that artifact as untrusted: for each package it takes only the new `pkgver`, re-applies the bump itself on the files from `main` (pkgver, pkgrel=1, `updpkgsums`, `makepkg --printsrcinfo`) and publishes only if its result is byte-identical to what was built. Then `scripts/publish-aur.sh <pkgbase>` and a bot commit on `main`. Any failed build, rejected artifact, or failed push turns the run red.
- Consequence: if aur-checker rewrote the `source=` URL (release asset renamed upstream), the re-derive differs and the package is rejected with a diff in the log. Apply that change by hand and push; the push path publishes it.
- **Push to `main` touching any file inside a package dir:** job `publish` checks `.SRCINFO` matches `makepkg --printsrcinfo`, then publishes exactly the changed dirs. No test build on this path: build locally first.
- Secrets: `AUR_SSH_KEY`, `AUR_COMMIT_NAME`, `AUR_COMMIT_EMAIL`. Running `scripts/publish-aur.sh` locally needs the two `AUR_COMMIT_*` env vars exported.
- New build dependency in a PKGBUILD? Job `update` pre-installs every `depends`/`makedepends`/`checkdepends` from the committed `.SRCINFO` files as root, so a dep that only appears in the *new* upstream version fails that run until you commit it.
- Two jobs on purpose: makepkg runs upstream code (npm postinstall, build.rs); it must never share a job with the AUR key. Keep it that way.

## Rules

- **Never push to AUR from a local machine.** Commit to `main`, push to GitHub, CI publishes. **Never force-push to AUR.**
- Every PKGBUILD must start with the maintainer comment line
- Always test build (`makepkg -s`), install (`sudo pacman -U`), and verify the binary works before committing
- Always regenerate `.SRCINFO` before committing: `makepkg --printsrcinfo > .SRCINFO`
- `pkgrel=1` for new versions; only increment pkgrel for same-version packaging fixes
- Use `/usr/bin/npm` or `/usr/bin/bun` full paths in PKGBUILDs to bypass version managers (nvm, asdf, mise)
- Use SPDX license identifiers and always install the LICENSE file
- Keep `README.md` package table in sync when adding/removing a package

## aur-checker

Local use of the same tool CI runs (source: https://codeberg.org/arch-linux-aur/aur-checker):

```bash
aur-checker check ~/other-repos/aur-packages          # upstream status for all 29
aur-checker update <pkg> --path ~/other-repos/aur-packages   # bump + checksums + .SRCINFO + test build, locally
aur-checker tui ~/other-repos/aur-packages
```

After a local update: review, `git commit`, push to GitHub. Do not use `aur-checker push` (there are no AUR remotes here).

## Creating a New Package

```bash
mkdir NEW-PKGBASE && cd NEW-PKGBASE
# write PKGBUILD (see templates), then:
makepkg -s && makepkg --printsrcinfo > .SRCINFO
cp ../ttl-bin/.gitignore .
```

Commit `PKGBUILD`, `.SRCINFO`, `.gitignore` (and `*.install` / local sources if any; add local sources to the dir's `.gitignore` whitelist). On push, CI clones `ssh://aur@aur.archlinux.org/NEW-PKGBASE.git` (AUR creates it empty on first access) and publishes.

### .gitignore (same for every package)

```gitignore
**
**/**
!.gitignore
!.SRCINFO
!PKGBUILD
!*.install
```

## Updating a Package Manually

```bash
# 1. Update pkgver in PKGBUILD (reset pkgrel=1)
updpkgsums
makepkg -si                          # build, install, verify binary
makepkg --printsrcinfo > .SRCINFO
git add PKGBUILD .SRCINFO && git commit -m "PKG: update to VERSION"
# 2. push to GitHub; CI publishes to AUR
```

## Adopting an Orphaned Package

```bash
git clone https://aur.archlinux.org/PKGBASE.git /tmp/PKGBASE   # read-only clone, outside this repo
mkdir PKGBASE && cp /tmp/PKGBASE/{PKGBUILD,.SRCINFO} PKGBASE/ && cp ../ttl-bin/.gitignore PKGBASE/
# Update maintainer line, add previous as # Contributor:, adopt on the AUR web UI, commit, push.
```

## Naming Conventions

| Suffix | Use Case | Example |
|--------|----------|---------|
| `-bin` | Pre-compiled binaries (.deb, tarball, zip) | `forgejo-mcp-bin`, `ttl-bin` |
| `-git` | Build from latest git commit | `mcp-cli-git` |
| (none) | Build from source tarball or npm registry | `agent-browser`, `pipenet` |

## PKGBUILD Templates

### Binary tarball (Go/Rust releases)

```bash
# Maintainer: Guru <anjanaya@gmail.com>
pkgname=PACKAGE-NAME-bin
pkgver=VERSION
pkgrel=1
pkgdesc="Short description"
arch=('x86_64')
url="https://upstream-website.com"
license=('MIT')
provides=('PACKAGE-NAME')
conflicts=('PACKAGE-NAME')
source=("${pkgname}-${pkgver}.tar.gz::https://example.com/releases/download/v${pkgver}/PACKAGE_${pkgver}_linux_amd64.tar.gz")
sha256sums=('CHECKSUM')

package() {
    cd "EXTRACTED-DIR-NAME"
    install -Dm755 BINARY "${pkgdir}/usr/bin/BINARY"
    install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
```

- Use `::` syntax to rename source: `"custom-name.tar.gz::https://..."`
- Check tarball structure first: `tar -tzf file.tar.gz`
- Get checksum: `sha256sum file.tar.gz`

### Binary tarball (multi-arch)

For packages with both x86_64 and aarch64 builds (see `ttl-bin`, `turso-cli-bin`):

```bash
arch=('x86_64' 'aarch64')
source_x86_64=("${pkgname}-${pkgver}-x86_64.tar.gz::https://example.com/releases/v${pkgver}/pkg_x86_64.tar.gz")
source_aarch64=("${pkgname}-${pkgver}-aarch64.tar.gz::https://example.com/releases/v${pkgver}/pkg_aarch64.tar.gz")
sha256sums_x86_64=('CHECKSUM')
sha256sums_aarch64=('CHECKSUM')
```

- Prebuilt single-file JS binaries (Node SEA, `bun build --compile`) need `options=('!strip')` -- stripping corrupts the appended code blob (see `varlock-bin`, a ~96MB SEA that links only base glibc, no `nodejs` dep).
- Prebuilt Go/Rust binaries shipped **not stripped** (carry debug_info) trigger makepkg's auto debug-split (a stray `*-debug` companion pkg) when `/etc/makepkg.conf` has `OPTIONS=(... debug ...)`. Add `options=('!debug')` to suppress it (see `qodana-cli-bin`). Distinct from `!strip` -- strip is still fine/wanted for Go.
- Some tools ship a sidecar helper binary that must be co-installed and found at runtime -- install it alongside the main binary in `/usr/bin` (varlock ships `varlock-local-encrypt`; verify the feature that uses it actually resolves the helper post-install).
- Monorepo releases often tag as `name@${pkgver}` (not `v${pkgver}`); the `@` is literal and works unencoded in the download URL.
- `updpkgsums` fetches every source array (incl. `source_x86_64`/`source_aarch64`) regardless of host arch, so one run fills all checksums. If upstream publishes a `checksums.txt`, cross-check against it.

### Binary .deb repackage

```bash
arch=('x86_64')
depends=('hicolor-icon-theme')  # Common for desktop apps
source=("https://example.com/download/package-${pkgver}-amd64.deb")
sha256sums=('CHECKSUM')
options=('!strip')

package() {
    bsdtar -xf "${srcdir}/data.tar.xz" -C "${pkgdir}"
}
```

### Node.js npm package

Per [Arch Node.js package guidelines](https://wiki.archlinux.org/title/Node.js_package_guidelines) (see `agent-browser`):

```bash
pkgname=PACKAGE-NAME
arch=('any')
depends=('nodejs')
makedepends=('npm' 'jq')
source=("https://registry.npmjs.org/${pkgname}/-/${pkgname}-${pkgver}.tgz")
noextract=("${pkgname}-${pkgver}.tgz")
sha256sums=('CHECKSUM')

package() {
    /usr/bin/npm install -g --cache "${srcdir}/npm-cache" --prefix "${pkgdir}/usr" "${srcdir}/${pkgname}-${pkgver}.tgz"

    # Fix permissions
    find "${pkgdir}/usr" -type d -exec chmod 755 {} +

    # Remove npm internal metadata from package.json
    local tmppackage="$(mktemp)"
    local pkgjson="${pkgdir}/usr/lib/node_modules/${pkgname}/package.json"
    jq '.|=with_entries(select(.key|test("_.+")|not))' "${pkgjson}" > "${tmppackage}"
    mv "${tmppackage}" "${pkgjson}"
    chmod 644 "${pkgjson}"

    # npm gives ownership of ALL FILES to build user (https://bugs.archlinux.org/task/63396)
    chown -R root:root "${pkgdir}"

    install -Dm644 "${pkgdir}/usr/lib/node_modules/${pkgname}/LICENSE" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
```

Critical npm packaging rules:
- Use `/usr/bin/npm` full path -- bare `npm` breaks under nvm/asdf/mise
- `--cache "${srcdir}/npm-cache"` keeps cache out of `~/.npm`
- `noextract=()` lets npm handle the tgz itself
- `jq` strips all `_`-prefixed npm internal keys from package.json
- `chown -R root:root` fixes npm's broken file ownership

### Bun compile from source (see `pipenet`, `mcp-cli-git`)

```bash
arch=('x86_64')
makedepends=('bun')
options=('!strip')

build() {
    cd "${pkgname}-${pkgver}"
    bun install
    bun build --compile --minify src/cli.ts --outfile BINARY
}

package() {
    install -Dm755 "${srcdir}/${pkgname}-${pkgver}/BINARY" "${pkgdir}/usr/bin/BINARY"
}
```

Use `/usr/bin/bun` if you need to bypass version managers (same issue as npm).

### Bun runtime with wrapper script (see `ralph-tui`)

When the package can't be compiled to a standalone binary:

```bash
arch=('any')
depends=('bun')

prepare() {
    cd "${srcdir}"
    mkdir -p "${pkgname}-${pkgver}"
    bsdtar -xf "${pkgname}-${pkgver}.tgz" -C "${pkgname}-${pkgver}" --strip-components=1
}

build() {
    cd "${srcdir}/${pkgname}-${pkgver}"
    /usr/bin/bun install --production
}

package() {
    cd "${srcdir}/${pkgname}-${pkgver}"
    install -dm755 "${pkgdir}/usr/lib/${pkgname}"
    cp -r . "${pkgdir}/usr/lib/${pkgname}"

    install -dm755 "${pkgdir}/usr/bin"
    cat > "${pkgdir}/usr/bin/${pkgname}" << 'EOF'
#!/bin/sh
exec bun run /usr/lib/PACKAGE-NAME/dist/cli.js "$@"
EOF
    chmod 755 "${pkgdir}/usr/bin/${pkgname}"

    install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
```

### Git source (-git package, see `mcp-cli-git`)

```bash
pkgname=PACKAGE-NAME-git
pkgver=VERSION  # Updated automatically by pkgver()
provides=('PACKAGE-NAME')
conflicts=('PACKAGE-NAME' 'PACKAGE-NAME-bin')
makedepends=('git' 'bun')  # or whatever build tool
source=("${pkgname}::git+https://github.com/owner/repo.git")
sha256sums=('SKIP')

pkgver() {
    cd "${pkgname}"
    git describe --long --tags --abbrev=7 2>/dev/null | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
}
```

## Shell Completions

Two approaches depending on what upstream provides:

### Generated at build time (see `ttl-bin`)

```bash
package() {
    install -Dm755 "${srcdir}/BINARY" "${pkgdir}/usr/bin/BINARY"

    "${srcdir}/BINARY" --completions bash | install -Dm644 /dev/stdin "${pkgdir}/usr/share/bash-completion/completions/BINARY"
    "${srcdir}/BINARY" --completions zsh  | install -Dm644 /dev/stdin "${pkgdir}/usr/share/zsh/site-functions/_BINARY"
    "${srcdir}/BINARY" --completions fish | install -Dm644 /dev/stdin "${pkgdir}/usr/share/fish/vendor_completions.d/BINARY.fish"
}
```

### Pre-built in release (see `turso-cli-bin`)

```bash
install -Dm644 "completions/pkg.bash" "${pkgdir}/usr/share/bash-completion/completions/pkg"
install -Dm644 "completions/pkg.zsh"  "${pkgdir}/usr/share/zsh/site-functions/_pkg"
install -Dm644 "completions/pkg.fish" "${pkgdir}/usr/share/fish/vendor_completions.d/pkg.fish"
```

Note: fish completions path can be either `fish/completions/` or `fish/vendor_completions.d/` -- both work.

## Install Scripts (.install files)

For post-install actions like setting capabilities (see `ttl-bin`):

```bash
# In PKGBUILD:
install=PACKAGE-NAME.install

# PACKAGE-NAME.install:
post_install() {
    setcap cap_net_raw+ep /usr/bin/BINARY
}

post_upgrade() {
    post_install
}
```

| Capability | Use Case |
|------------|----------|
| `cap_net_raw+ep` | Raw sockets (traceroute, ping) |
| `cap_net_admin+ep` | Network admin (interface config) |
| `cap_sys_ptrace+ep` | Process tracing (debuggers) |

## License Notes

- Use SPDX identifiers: `MIT`, `GPL-3.0-only`, `Apache-2.0`, `BSD-3-Clause`
- Always install license file: `install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"`
- Multiple licenses are fine: `license=('Apache-2.0' 'MIT')`
- **LICENSE not bundled in the release tarball?** Pull it from the repo tag as a separate non-arch `source=()` entry, then install from `${srcdir}` (see `varlock-bin`):
  ```bash
  source=("LICENSE-${pkgver}::https://raw.githubusercontent.com/OWNER/REPO/TAG/LICENSE")
  sha256sums=('CHECKSUM')   # non-arch array, applies to the LICENSE source
  ...
  install -Dm644 "${srcdir}/LICENSE-${pkgver}" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
  ```
  Keep it in the plain `source=()`/`sha256sums=()` arrays (no arch suffix) so it isn't fetched once per arch. Confirm the upstream license via `gh api repos/OWNER/REPO/license --jq .license.spdx_id`.

## Links

- [AUR Submission Guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines)
- [PKGBUILD Reference](https://wiki.archlinux.org/title/PKGBUILD)
- [Node.js Package Guidelines](https://wiki.archlinux.org/title/Node.js_package_guidelines)
