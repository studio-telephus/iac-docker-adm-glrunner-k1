#!/usr/bin/env bash
: "${GITLAB_ADDRESS?}"
: "${GITLAB_RUNNER_REGISTRATION_KEY?}"

echo "Register GitLab Runner"

# Disable skel & install
export GITLAB_RUNNER_DISABLE_SKEL=true

gitlab-runner register \
    --non-interactive \
    --url $GITLAB_ADDRESS \
    --registration-token "$GITLAB_RUNNER_REGISTRATION_KEY" \
    --tag-list "k3s-dev,terraform,bw" \
    --executor shell
