#!/usr/bin/env bash
# Export local commits of every SDK project into patches/<project path>/.
# Commits are taken from BASE (the pristine SDK revision) up to HEAD.
set -euo pipefail

TOP=$(cd "$(dirname "$0")/.." && pwd)
BASE=${BASE:-m/luckfox-release}

cd "$TOP"

while read -r proj; do
	[ -e "$proj/.git" ] || continue
	git -C "$proj" rev-parse -q --verify "$BASE" >/dev/null || continue

	out="patches/$proj"
	rm -f "$out"/*.patch

	count=$(git -C "$proj" rev-list --count "$BASE..HEAD")
	[ "$count" -gt 0 ] || continue

	if ! git -C "$proj" diff --quiet HEAD; then
		echo "warning: $proj has uncommitted changes, they are not exported" >&2
	fi

	git -C "$proj" format-patch --quiet --zero-commit --no-signature \
		-o "$TOP/$out" "$BASE..HEAD"
	echo "$proj: $count patch(es)"
done < .repo/project.list
