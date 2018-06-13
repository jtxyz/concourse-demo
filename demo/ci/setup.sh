#!/usr/bin/env bash

set -e -u -x

# setup concourse keys so web and worker can communicate
mkdir -p keys/web keys/worker

ssh-keygen -t rsa -f ./keys/web/tsa_host_key -N ''
ssh-keygen -t rsa -f ./keys/web/session_signing_key -N ''

ssh-keygen -t rsa -f ./keys/worker/worker_key -N ''

cp ./keys/worker/worker_key.pub ./keys/web/authorized_worker_keys
cp ./keys/web/tsa_host_key.pub ./keys/worker

# setup the ssh keys that concouse will use to talk to git
mkdir -p keys/ssh
ssh-keygen -t rsa -f ./keys/ssh/id -N ''

awk 'BEGIN{
  print "---"
  print "ssh-key: |"
}{
  print "  " $0
}' ./keys/ssh/id > ./keys/secrets.yml

rm ./keys/ssh/id

# create the directory to store the git repo
mkdir -p repos
git clone --bare git@github.com:Kehrlann/concourse-demo.git repos/concourse-demo.git

mkdir -p registry
