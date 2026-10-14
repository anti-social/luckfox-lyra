# Shared settings for apply-patches.sh and export-patches.sh.

TOP=$(cd "$(dirname "$0")/.." && pwd)
BASE=${BASE:-m/luckfox-release}
BRANCH=${BRANCH:-main}

# The repo tool itself is not in the manifest, so it has its own base and branch.
REPO_TOOL=.repo/repo
REPO_TOOL_BASE=v1.12.37
REPO_TOOL_BRANCH=default

# All projects that may carry patches: the repo tool and every SDK project.
list_projects()
{
	echo "$REPO_TOOL"
	cat "$TOP/.repo/project.list"
}

project_base()
{
	if [ "$1" = "$REPO_TOOL" ]; then echo "$REPO_TOOL_BASE"; else echo "$BASE"; fi
}

project_branch()
{
	if [ "$1" = "$REPO_TOOL" ]; then echo "$REPO_TOOL_BRANCH"; else echo "$BRANCH"; fi
}
