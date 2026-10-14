#!/usr/bin/env bash
# Apply patches/<project path>/*.patch as commits on top of the pristine SDK
# revision (BASE) in each project. The project's current branch is reset to
# BASE first; its previous state is kept in the "<branch>-prev" branch.
set -euo pipefail

TOP=$(cd "$(dirname "$0")/.." && pwd)
BASE=${BASE:-m/luckfox-release}
BRANCH=${BRANCH:-main}

cd "$TOP"

# Check everything first so we never stop half-way because of a dirty tree.
projects=()
while read -r proj; do
	[ -n "$(find "patches/$proj" -maxdepth 1 -name '*.patch' 2>/dev/null)" ] || continue
	if ! git -C "$proj" diff --quiet HEAD; then
		echo "error: $proj has uncommitted changes, commit or stash them first" >&2
		exit 1
	fi
	projects+=("$proj")
done < .repo/project.list

for proj in "${projects[@]}"; do
	git -C "$proj" branch -f "$BRANCH-prev" HEAD
	git -C "$proj" switch -q -C "$BRANCH" "$BASE"
	git -C "$proj" am -q --3way "$TOP/patches/$proj"/*.patch
	echo "$proj: $(git -C "$proj" rev-list --count "$BASE..HEAD") patch(es) applied on $BRANCH"
done
