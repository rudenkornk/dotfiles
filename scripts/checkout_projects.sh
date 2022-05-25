#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

if [[ -z "${PROJECTS_PATH:-}" ]]; then
  echo "Please set PROJECTS_PATH var"
  exit 1
fi

mkdir --parents "$PROJECTS_PATH"

REPOS=()
REPOS+=("git@github.com:rudenkornk/cpp_contests.git")
REPOS+=("git@github.com:rudenkornk/docker_ci.git")
REPOS+=("git@github.com:rudenkornk/docker_cpp.git")
REPOS+=("git@github.com:rudenkornk/docker_latex.git")
REPOS+=("git@github.com:rudenkornk/group_theory.git")
REPOS+=("git@github.com:rudenkornk/latex_experiments.git")

for r in ${REPOS[@]}; do
  REPO_NAME=$(echo $r | grep -oP "git@github\.com:.*?/\K.*?(?=\.git)")
  REPO_PATH="$PROJECTS_PATH/$REPO_NAME"
  git clone $r "$REPO_PATH"
  git --git-dir="$REPO_PATH/.git" checkout -b dev_volatile
  git --git-dir="$REPO_PATH/.git" branch -D main
done

