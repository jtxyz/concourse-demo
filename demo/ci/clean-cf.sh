#!/bin/bash

cf t -s dev
cf d -f web-app
cf d -f backend

cf t -s prod
cf d -f web-app
cf d -f backend
