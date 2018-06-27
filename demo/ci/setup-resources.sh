#!/usr/bin/env bash
set -eu

export AWS_ACCESS_KEY_ID=minio
export AWS_SECRET_ACCESS_KEY=changeme
if ! aws --endpoint-url http://localhost:9000 s3 ls todo-version >/dev/null 2>&1; then
  for bucket in todo-backend todo-frontend todo-app todo-version; do
    aws --endpoint-url http://localhost:9000 s3api create-bucket --bucket $bucket --output text
  done
else
  echo '√ s3 buckets already exist'
fi

if ! curl -s localhost:5000/v2/_catalog | grep alpine -q; then
  docker pull alpine
  docker tag alpine localhost:5000/alpine
  docker push localhost:5000/alpine
else
  echo '√ local alpine repo already exists'
fi

export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN=8568d046-b70a-64f6-ebfe-ec2a891a8ba3
if ! vault secrets list | grep -q concourse/; then
  vault secrets enable -path=concourse kv
else
  echo '√ concourse secret engine already enabled'
fi

# setup the ssh keys that concouse will use to talk to git
if ! [ -e keys/ssh/id -a -e keys/ssh/id.pub ]; then
  ssh-keygen -t rsa -f ./keys/ssh/id -N ''
  vault kv delete concourse/main/id-rsa-git
else
  echo '√ key already exists'
fi

if ! vault list concourse/main/ | grep -q id-rsa-git; then
  vault kv put concourse/main/id-rsa-git value=@keys/ssh/id
else
  echo '√ git rsa key already stored in vault'
fi

if ! vault token lookup 35eb29c4-1635-40b6-85fe-3684f8006f86 >/dev/null 2>&1; then
  vault token create -ttl 15m -id 35eb29c4-1635-40b6-85fe-3684f8006f86
else
  echo '√ temporary token already created'
fi

# create the directory to store the git repo
if [ ! -e repos/concourse-demo.git ]; then
  git clone --bare git@github.com:Kehrlann/concourse-demo.git repos/concourse-demo.git
else
  echo '√ repo already exists'
fi

if ! vault list concourse/main/ | grep -q cf; then
  if [ -z "${CF_API:-}" -o -z "${CF_USERNAME:-}" -o -z "${CF_PASSWORD:-}" -o -z "${CF_ORGANIZATION:-}" ]; then
    echo 'unable to configure vault with CF creds'
    echo '  set CF_API, CF_USERNAME, CF_PASSWORD and CF_ORGANIZATION and rerun to configure cf credetials vault'
    echo '  or run `vault kv put concourse/main/cf api=<CF_API> username=<CF_USERNAME> password=<CF_PASSWORD> organization=<CF_ORGANIZATION>`'
  else
    vault kv put concourse/main/cf api="$CF_API" username="$CF_USERNAME" password="$CF_PASSWORD" organization="$CF_ORGANIZATION"
  fi
else
  echo '√ cf credentials already configured in vault'
fi
