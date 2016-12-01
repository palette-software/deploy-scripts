#!/usr/bin/env bash

# Stop on the first error
set -e

if [[ -z $DEPLOY_HOST ]]; then echo "DEPLOY_HOST environment variable is not set!"; exit 1; fi
if [[ -z $DEPLOY_USER ]]; then echo "DEPLOY_USER environment variable is not set!"; exit 1; fi
if [[ -z $DEPLOY_PATH ]]; then echo "DEPLOY_PATH environment variable is not set!"; exit 1; fi
if [[ -z $DEPLOY_PASS ]]; then echo "DEPLOY_PASS environment variable is not set!"; exit 1; fi
if [[ -z $DEPLOY_FILE ]]; then echo "DEPLOY_FILE environment variable is not set!"; exit 1; fi

# Upload the RPM to the RPM repository
# by exportin it to SSHPASS, sshpass wont log the command line and the password
export SSHPASS=$DEPLOY_PASS
sshpass -e scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ${DEPLOY_FILE} $DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH

# Update the RPM repository
export DEPLOY_CMD="createrepo ${DEPLOY_PATH}/"
sshpass -e ssh  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $DEPLOY_USER@$DEPLOY_HOST $DEPLOY_CMD

# The existence of GITHUB_TOKEN variable is the switch for Github release
if [[ -n $GITHUB_TOKEN ]]; then
	# Get the directory of current .sh script
	SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	pushd ${SCRIPT_DIR}/github
	# This script is expected to be executed from its folder
	./release-to-github.sh
	popd
fi