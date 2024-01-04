#!/usr/bin/env bash
: "${GITLAB_RUNNER_REGISTRATION_KEY?}"
: "${GIT_SA_USERNAME?}"
: "${GIT_SA_TOKEN?}"

##
echo "Install the base tools"

apt-get update && apt-get install -y \
 curl vim wget htop unzip gnupg2 netcat-traditional \
 bash-completion git apt-transport-https ca-certificates \
 software-properties-common

## Run pre-install scripts
sh /mnt/setup-ca.sh


##
echo "Install GitLab Runner"

# Add the official GitLab repository
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash

# Disable skel & install
export GITLAB_RUNNER_DISABLE_SKEL=true
apt-get install gitlab-runner -y

echo "Register GitLab Runner"
gitlab-runner register \
    --non-interactive \
    --url https://gitlab.adm.acme.corp/gitlab \
    --registration-token "$GITLAB_RUNNER_REGISTRATION_KEY" \
    --tag-list "k3s-dev" \
    --executor shell

export cred_home="/home/gitlab-runner"

echo "Create GitLab credentials file"
cat << EOF > ${cred_home}/.my-git-credentials
https://${GIT_SA_USERNAME}:${GIT_SA_TOKEN}@gitlab.adm.acme.corp
EOF

echo "Set ownership & permissions of .my-git-credentials"
chmod 644 ${cred_home}/.my-git-credentials

echo "Add Github credentials to git global config file"
cat << EOF > ${cred_home}/.gitconfig
[credential]
	helper = store --file ${cred_home}/.my-git-credentials
[user]
	user = ${GIT_SA_USERNAME}
	email = ${GIT_SA_USERNAME}@mail.adm.acme.corp
EOF

echo "Set ownership & permissions"
chmod 644 ${cred_home}/.gitconfig
chown -R gitlab-runner:gitlab-runner /home/gitlab-runner

##
echo "Install Terraform"

#### The Terraform packages are signed using a private key controlled by HashiCorp, so in most situations the first step would be to configure your system to trust that HashiCorp key for package authentication.
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
#### After registering the key, you can add the official HashiCorp repository to your system:
apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update
apt-get install terraform=1.5.7-1 -y

echo "To resolve a complaint that it needs the GPG keys in gpg.d directory"
cp /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d

##
echo "Install K8S tools through Arkade"

curl -sLS https://get.arkade.dev | sh
arkade get kubectl kubectx kubens helm skaffold
chmod 755 /root/.arkade/bin/*
mv /root/.arkade/bin/* /usr/local/bin/.


curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && \
sudo install skaffold /usr/local/bin/
