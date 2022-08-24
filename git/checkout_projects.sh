#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

PROJECTS_PATH=$(realpath "$(dirname "$0")/../..")

REPOS=()
REPOS+=("git@github.com:rudenkornk/cpp_contests.git")
REPOS+=("git@github.com:rudenkornk/docker_ci.git")
REPOS+=("git@github.com:rudenkornk/docker_cpp.git")
REPOS+=("git@github.com:rudenkornk/docker_cpp_windows.git")
REPOS+=("git@github.com:rudenkornk/docker_latex.git")
REPOS+=("git@github.com:rudenkornk/dotfiles.git")
REPOS+=("git@github.com:rudenkornk/group_theory.git")
REPOS+=("git@github.com:rudenkornk/latex_experiments.git")

if ssh -q git@github.com; [ ! $? -eq 1 ]; then
  echo "Cannot login to GitHub, check ssh keys."
  exit 1
fi

for URL in "${REPOS[@]}"; do
  REPO_NAME=$(echo "$URL" | grep --only-matching --perl-regexp "git@git.*?\.com:(.*?/)+\K.*?(?=\.git)")
  echo "$REPO_NAME"
  REPO_PATH="$PROJECTS_PATH/$REPO_NAME"
  if [[ ! -d "$REPO_PATH" ]]; then
    git clone "$URL" "$REPO_PATH"
    git --git-dir="$REPO_PATH/.git" checkout -b dev_volatile --track origin/main
    git --git-dir="$REPO_PATH/.git" branch -D main
  fi
  git --git-dir="$REPO_PATH/.git" config user.email "rudenkornk@gmail.com"
  REMOTES=$(git --git-dir="$REPO_PATH/.git" remote --verbose)
  if ! echo $REMOTES | grep --quiet "origin git@git"; then # NOLINT
    if echo $REMOTES | grep --quiet "origin "; then # NOLINT
      git --git-dir="$REPO_PATH/.git" remote remove origin
    fi
    git --git-dir="$REPO_PATH/.git" remote add origin "$URL"
  fi
done

