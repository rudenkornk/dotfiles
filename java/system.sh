#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
  openjdk-18-jdk \

if ! gradle --version; then
  wget https://services.gradle.org/distributions/gradle-7.5.1-bin.zip
  mkdir /opt/gradle
  unzip -d /opt/gradle gradle-7.5.1-bin.zip
  ln -sf /opt/gradle/gradle-7.5.1/bin/gradle /usr/local/bin/gradle
  rm gradle-7.5.1-bin.zip
fi
