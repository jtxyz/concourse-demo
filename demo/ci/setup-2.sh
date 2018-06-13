#!/usr/bin/env bash

set -e -u -x

export AWS_ACCESS_KEY_ID=minio
export AWS_SECRET_ACCESS_KEY=changeme

for bucket in todo-backend todo-frontend todo-app todo-version; do
  aws --endpoint-url http://localhost:9000 s3api create-bucket --bucket $bucket
done

docker pull alpine
docker tag alpine localhost:5000/alpine
docker push localhost:5000/alpine
