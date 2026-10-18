#!/usr/bin/env bash
# Publish one package dir of this monorepo to its AUR repo.
# Usage: scripts/publish-aur.sh <pkgbase>   (run from the repo root)
# Clones the AUR repo fresh, copies every git-tracked file of the dir over
# (PKGBUILD, .SRCINFO, .gitignore, *.install, local sources), commits, pushes.
# Never force-pushes: a non-fast-forward (someone else pushed) fails loudly.
# Commit identity comes from env (repo secrets in CI): AUR_COMMIT_NAME, AUR_COMMIT_EMAIL.
set -euo pipefail
: "${AUR_COMMIT_NAME:?set AUR_COMMIT_NAME}" "${AUR_COMMIT_EMAIL:?set AUR_COMMIT_EMAIL}"

d=${1:?usage: $0 <pkgbase>}
[ -f "$d/PKGBUILD" ] && [ -f "$d/.SRCINFO" ] || { echo "$d: missing PKGBUILD or .SRCINFO" >&2; exit 1; }
grep -qxF -- "pkgbase = $d" "$d/.SRCINFO" || { echo "$d: dir name != pkgbase in .SRCINFO" >&2; exit 1; }

tmp=$(mktemp -d)
git clone --quiet "ssh://aur@aur.archlinux.org/${d}.git" "$tmp"
git -C "$tmp" rm -rq --ignore-unmatch . 2>/dev/null || true   # mirror semantics: files dropped here are dropped on AUR
(cd "$d" && git ls-files -z | xargs -0 cp --parents -t "$tmp")

cd "$tmp"
git add -A
if git diff --cached --quiet; then
    echo "$d: nothing to publish"
    exit 0
fi
ver="$(sed -n 's/^\tpkgver = //p' .SRCINFO)-$(sed -n 's/^\tpkgrel = //p' .SRCINFO)"
git -c user.name="$AUR_COMMIT_NAME" -c user.email="$AUR_COMMIT_EMAIL" commit -qm "Update to ${ver}"
git push --quiet origin HEAD:master
echo "$d: published ${ver}"
