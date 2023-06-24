#!/bin/bash
#
# Read configuration
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

# Read file with repos - exlclude empty line and comments
REPOS=$(cat repos | grep -v '^$\|^#')

for REPO in $REPOS; do
	echo "r: $REPO"
done
