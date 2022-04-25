#!/usr/bin/env bash

#set -x

REPOS_DIR=$HOME/projects

mkdir --parents $REPOS_DIR

REPOS=()
REPOS+=("git@github.com:rudenkornk/docker_latex.git")
REPOS+=("git@github.com:rudenkornk/latex_experiments.git")
REPOS+=("git@github.com:rudenkornk/docker_ci.git")
REPOS+=("git@github.com:rudenkornk/group_theory.git")

for r in ${REPOS[@]}; do
  REPO_NAME=$(echo $r | grep -oP "git@github\.com:.*?/\K.*?(?=\.git)")
  git clone $r $REPOS_DIR/$REPO_NAME
done


