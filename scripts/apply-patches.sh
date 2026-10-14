#!/usr/bin/env bash
# Apply patches/<project path>/*.patch as commits on top of the pristine SDK
# revision in each project (or only in the projects given as arguments).
# The project's branch is reset to the base first; its previous state is kept
# in the "<branch>-prev" branch.
set -euo pipefail

source "$(dirname "$0")/common.sh"

cd "$TOP"

if [ $# -gt 0 ]; then
	candidates=("$@")
else
	mapfile -t candidates < <(list_projects)
fi

# Check everything first so we never stop half-way because of a dirty tree.
projects=()
for proj in "${candidates[@]}"; do
	[ -n "$(find "patches/$proj" -maxdepth 1 -name '*.patch' 2>/dev/null)" ] || continue
	if [ ! -e "$proj/.git" ]; then
		echo "error: $proj is not checked out, run .repo/repo/repo sync -l first" >&2
		exit 1
	fi
	if ! git -C "$proj" diff --quiet HEAD; then
		echo "error: $proj has uncommitted changes, commit or stash them first" >&2
		exit 1
	fi
	projects+=("$proj")
done

for proj in "${projects[@]}"; do
	base=$(project_base "$proj")
	branch=$(project_branch "$proj")
	git -C "$proj" branch -f "$branch-prev" HEAD
	git -C "$proj" switch -q -C "$branch" "$base"
	git -C "$proj" am -q --3way "$TOP/patches/$proj"/*.patch
	echo "$proj: $(git -C "$proj" rev-list --count "$base..HEAD") patch(es) applied on $branch"
done
