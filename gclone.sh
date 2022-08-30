#!/usr/bin/env bash
# Install LFS:
# sudo pacman -S git-lfs && git lfs install
#
# Clone Git repositories and download LFS files in parallel
#
set -e

CLEAN_ERROR='push @lines, $_;splice @lines, 0, 7 if /error: external filter  failed/;print shift @lines if @lines > 6}{ print @lines;'

git -c filter.lfs.smudge= \
    -c filter.lfs.required=false \
    clone $@ 2>&1 | perl -ne "$CLEAN_ERROR"

if [[ -z $2 ]]; then
    CLONE_PATH="$(basename ${1%.git})";
else
    CLONE_PATH="$2";
fi
cd "$CLONE_PATH"
git-lfs pull

# Running `pull` a second time as a workaround for a Git-LFS bug
# c.f. https://github.com/github/git-lfs/issues/904#issuecomment-169092031
git-lfs pull
