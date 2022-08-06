#!/bin/bash
set -e
argv0=sync-devel
XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}

# For the purposes of this example, we assume AURDEST contains both AUR and
# non-AUR git repositories (e.g. from github or archweb), with corresponding
# packages in the local repository.
AURDEST=${AURDEST:-$XDG_CACHE_HOME/aurutils/sync}
AURVCS=".*-(cvs|svn|git|hg|bzr|darcs)$"

# Pattern that defines VCS packages. The AUR has no formal definition of a VCS
# package - here we include the most common version control systems.
filter_vcs() {
	awk -v "mask=$AURVCS" '$1 ~ mask {print $1}' "$@"
}

# Scratch space for intermediary results.
tmp=$(mktemp -d --tmpdir "$argv0.XXXXXXXX")
trap 'rm -rf "$tmp"' EXIT

# Retrieve a list of the local repository contents. The repository
# can be specified with the usual aur-repo arguments.
aur repo --list "$@" | tee "$tmp"/db | filter_vcs - >"$tmp"/vcs

# Only AUR repositories can be cloned anew, as the source of non-AUR packages
# is unknown beforehand. Their existence is checked with `git-ls-remote` (`-e`)
# Running makepkg locally on a PKGBUILD with pkgver() results in local changes,
# so these are removed with `--discard`. New upstream commits are then merged
# with `git-merge` or `git-rebase` (`--sync=auto`). The final PKGBUILD is shown
# in `aur-view` later on.
cd "$AURDEST"
aur fetch -e --discard --sync=auto --results="$tmp"/fetch_results - <"$tmp"/vcs

# Make sure empty repositories are not considered for inspection.
targets=()
while IFS=: read -r mode rev_old rev path; do
	path=${path#file://} name=${path##*/}

	case $mode in
		(clone|merge|fetch|rebase|reset)
			[[ $rev != "0" ]] && targets+=("$name") ;;
	esac
done <"$tmp"/fetch_results

# Inspect new AUR (downstream) commits with aur-view(1). This is done
# before running aur-srcver, which runs makepkg and sources the
# PKGBUILD.

aur view --format diff "${targets[@]}"

# Update `epoch:pkgver-pkgrel` for each target with `aur-srcver`.
# This runs `makepkg`, cloning upstream to the latest revision. The
# output is then compared with the contents of the local repository.
cat "$tmp"/db | aur vercmp -p <(aur srcver "${targets[@]}") | \
	awk '{print $1}' >"$tmp"/ood

# Build the packages. Arguments are shared between aur-repo and
# aur-build to specify the local repository.

if [[ -s $tmp/ood ]]; then
	aur build "$@" -a "$tmp"/ood --syncdeps --rmdeps --noconfirm
else
	printf >&2 '%s: all packages up-to-date\n' "$argv0"
fi
