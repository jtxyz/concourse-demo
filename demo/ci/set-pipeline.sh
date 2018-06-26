#!/bin/bash

fly -t ci set-pipeline -p pipeline -c pipeline.yml
