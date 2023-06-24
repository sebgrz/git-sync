#!/bin/bash
#
# GLOBALS
# Read configuration
REPO_TEMP_DIR="repo"
GITHUB_TEMP_DIR="$REPO_TEMP_DIR/gh_temp"
GITLAB_TEMP_DIR="$REPO_TEMP_DIR/gl_temp"

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
	git clone --bare $GIT_URL $GITHUB_TEMP_DIR 

	echo $GITHUB_TEMP_DIR #RETURN
}

clone_gitlab () {
	local USERNAME=${GITLAB_CONFIG[username]}
	local TOKEN=${GITLAB_CONFIG[token]}
	local HTTPS=${GITLAB_CONFIG[https]}
	local HOST=${GITLAB_CONFIG[host]}
	local PROJECT=$1
	local GIT_DIR_TO_SYNC=$2
	local PROTOCOL="http://"

	if [[ $HTTPS = "true" ]]
	then
		PROTOCOL="https://"
	fi

	local GIT_URL="$PROTOCOL$USERNAME:$TOKEN@$HOST/$PROJECT.git"
	git clone --bare $GIT_URL $GITLAB_TEMP_DIR

	echo $GITLAB_TEMP_DIR #RETURN
}

clone_repo () {
	local PROVIDER=$(echo $1 | cut -d ':' -f1)
	local REPO_PROJECT=$(echo $1 | cut -d ':' -f2)

	case $PROVIDER in
		"gh"*)
			echo $(clone_github $REPO_PROJECT) #RETURN
			;;
		"gl"*)
			echo $(clone_gitlab $REPO_PROJECT) #RETURN
			;;
	esac
}

create_github_project () {
	local PROJECT=$1
	local PROJECT_NAME=$(echo $PROJECT | cut -d '/' -f2)
	
	local BODY="
		{
			\"name\": \"$PROJECT_NAME\",
			\"private\": true,
			\"is_template\": false
		}";

	curl -L \
		-X POST \
		-H "Accept: application/vnd.github+json" \
		-H "Authorization: Bearer ${GITHUB_CONFIG[token]}"\
		-H "X-GitHub-Api-Version: 2022-11-28" \
		https://api.github.com/user/repos \
		-d "$BODY" \
		--silent \
		--output /dev/null
}

push_command () {
	local GIT_URL=$1
	local GIT_DIR_TO_SYNC=$2
	echo $(cd $GIT_DIR_TO_SYNC && git push --mirror $GIT_URL 2>&1)
}

push_github () {
	local USERNAME=${GITHUB_CONFIG[username]}
	local TOKEN=${GITHUB_CONFIG[token]}
	local PROJECT=$1
	local GIT_DIR_TO_SYNC=$2
	local GIT_URL="https://$USERNAME:$TOKEN@github.com/$PROJECT.git"

	local PUSH_RESULT=$(push_command $GIT_URL $GIT_DIR_TO_SYNC)
	if [[ $PUSH_RESULT == *"not found"* ]]; then
		create_github_project $PROJECT
		push_command $GIT_URL $GIT_DIR_TO_SYNC > /dev/null
	fi
}

push_gitlab () {
	local USERNAME=${GITLAB_CONFIG[username]}
	local TOKEN=${GITLAB_CONFIG[token]}
	local HTTPS=${GITLAB_CONFIG[https]}
	local HOST=${GITLAB_CONFIG[host]}
	local PROJECT=$1
	local GIT_DIR_TO_SYNC=$2
	local PROTOCOL="http://"

	if [[ $HTTPS = "true" ]]
	then
		PROTOCOL="https://"
	fi
	local GIT_URL="$PROTOCOL$USERNAME:$TOKEN@$HOST/$PROJECT.git"
	push_command $GIT_URL $GIT_DIR_TO_SYNC > /dev/null
}

push_repo () {
	local REPO_DIR=$2
	local PROVIDER=$(echo $1 | cut -d ':' -f1)
	local REPO_PROJECT=$(echo $1 | cut -d ':' -f2)

	case $PROVIDER in
		"gh"*)
			push_github $REPO_PROJECT $REPO_DIR
			;;
		"gl"*)
			push_gitlab $REPO_PROJECT $REPO_DIR
			;;
	esac
}

# MAIN
# Read file with repos - exlclude empty line and comments

mkdir -p $GITHUB_TEMP_DIR
mkdir -p $GITLAB_TEMP_DIR

REPOS=$(cat repos | grep -v '^$\|^#')

for REPO in $REPOS; do
	ORIGIN_REPO_PROJECT=$(echo $REPO | cut -d '|' -f1)
	BACKUP_REPO_PROJECT=$(echo $REPO | cut -d '|' -f2)
	REPO_DIR=$(clone_repo $ORIGIN_REPO_PROJECT)
	push_repo $BACKUP_REPO_PROJECT $REPO_DIR

	# Remove temp dir
	rm -rf $REPO_TEMP_DIR
done

