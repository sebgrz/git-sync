#!/bin/bash
#
# GLOBALS
# Read configuration
GITHUB_TEMP_DIR="gh_temp"
GITLAB_TEMP_DIR="gl_temp"
REPO_TEMP_DIR="repo"

CONFIG_DATA=$(cat config.json)
GH_CONFIG_DATA=$(echo $CONFIG_DATA | jq .gh)
declare -A GITHUB_CONFIG=(
	[username]=$(echo $GH_CONFIG_DATA | jq -r .username)
	[token]=$(echo $GH_CONFIG_DATA | jq -r .token)
)

GL_CONFIG_DATA=$(echo $CONFIG_DATA | jq .gl)
declare -A GITLAB_CONFIG=(
	[https]=$(echo $GL_CONFIG_DATA | jq -r .https)
	[host]=$(echo $GL_CONFIG_DATA | jq -r .host)
	[username]=$(echo $GL_CONFIG_DATA | jq -r .username)
	[token]=$(echo $GL_CONFIG_DATA | jq -r .token)
)

# FUNCTIONS

clone_github () {
	local USERNAME=${GITHUB_CONFIG[username]}
	local TOKEN=${GITHUB_CONFIG[token]}
	local PROJECT=$1
	local GIT_URL="https://$USERNAME:$TOKEN@github.com/$PROJECT.git"
	git clone --bare $GIT_URL $REPO_TEMP_DIR/$GITHUB_TEMP_DIR
}

clone_repo () {
	local PROVIDER=$(echo $1 | cut -d ':' -f1)
	local REPO_PROJECT=$(echo $1 | cut -d ':' -f2)

	echo "p: $PROVIDER rp: $REPO_PROJECT"

	case $PROVIDER in
		"gh"*)
			clone_github $REPO_PROJECT
			;;
		"gl"*)
			echo "UNIMPLEMENTED"
			;;
	esac
}

# MAIN
# Read file with repos - exlclude empty line and comments
mkdir -p $REPO_TEMP_DIR/$GITHUB_TEMP_DIR
mkdir -p $REPO_TEMP_DIR/$GITLAB_TEMP_DIR

REPOS=$(cat repos | grep -v '^$\|^#')

for REPO in $REPOS; do
	ORIGIN_REPO_PROJECT=$(echo $REPO | cut -d '|' -f1)
	BACKUP_REPO_PROJECT=$(echo $REPO | cut -d '|' -f2)
	echo -e "o:\n $(clone_repo $ORIGIN_REPO_PROJECT)\nb:\n $(clone_repo $BACKUP_REPO_PROJECT) \n\n"
done

