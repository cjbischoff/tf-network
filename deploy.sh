#!/bin/bash

set -o errexit -o nounset

cd ue1

terraform init

terraform validate

terraform plan

terraform apply
