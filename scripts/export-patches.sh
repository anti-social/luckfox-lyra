#!/usr/bin/env bash
# Export local commits of the repo tool and every SDK project into
# patches/<project path>/. Commits are taken from the project's base (the
# pristine SDK revision) up to HEAD.
set -euo pipefail

source "$(dirname "$0")/common.sh"

cd "$TOP"

list_projects | while read -r proj; do
	[ -e "$proj/.git" ] || continue
	base=$(project_base "$proj")
	git -C "$proj" rev-parse -q --verify "$base" >/dev/null || continue

	out="patches/$proj"
	rm -f "$out"/*.patch

	count=$(git -C "$proj" rev-list --count "$base..HEAD")
	[ "$count" -gt 0 ] || continue

	if ! git -C "$proj" diff --quiet HEAD; then
		echo "warning: $proj has uncommitted changes, they are not exported" >&2
	fi

	git -C "$proj" format-patch --quiet --zero-commit --no-signature \
		-o "$TOP/$out" "$base..HEAD"
	echo "$proj: $count patch(es)"
done
