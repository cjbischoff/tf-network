#!/bin/bash

set -o errexit -o nounset

cd ue1

terraform init -input=false

terraform validate

terraform plan

terraform apply -input=false -auto-approve
