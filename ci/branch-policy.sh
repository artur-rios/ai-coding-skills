#!/bin/sh
# The part of the old Branch Policy workflow that yggdrasil's common branch policy does not know: a pull request from
# release/x.y.z into main must find its version in CHANGELOG.md, as the workflow's "Validate release version" step
# required. The skills have no version file, so a release's version is its changelog heading and its tag.
# yggdrasil.yml runs this as `branchPolicy`, after scripts/branch-policy.sh (which already holds the branch names, the
# snapshot-of-develop rule and "the version has no tag yet"), in a small image from the root of the pull request's head
# checkout, with HEAD_REF and BASE_REF set. Without them -- on your machine -- pass the two refs as arguments:
#   sh ci/branch-policy.sh release/1.2.3 main
# Only a pull request into main from release/<major>.<minor>.<patch> is checked; anything else is already judged by
# scripts/branch-policy.sh.
set -eu
cd "$(dirname "$0")/.."

head_ref=${1:-${HEAD_REF:-}}
base_ref=${2:-${BASE_REF:-}}

case $base_ref:$head_ref in
  main:release/[0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "'$head_ref' -> '$base_ref': nothing more to check."; exit 0 ;;
esac
version=${head_ref#release/}

if ! tr -d '\r' < CHANGELOG.md | grep -qF "## [$version] - "; then
  echo "CHANGELOG.md has no '## [$version] - <yyyy-mm-dd>' section. A release branch carries no commits of its own: rename '## [Unreleased]' to it on develop (with a fresh, empty '## [Unreleased]' above), then cut the release branch again." >&2
  exit 1
fi
echo "CHANGELOG.md has the section for $version, as the release does."
