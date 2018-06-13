#!/bin/bash

set -eu

cd repo/demo/frontend
mv /tmp/node_modules .

APP_URL=https://todo-dev.pcfbeta.io yarn e2e-ci
