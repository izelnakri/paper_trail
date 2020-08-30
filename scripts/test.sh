#!/bin/bash
set -aeuo pipefail

DOCKER_TAG=$(git rev-parse --short HEAD)
source .env

mix test test/paper_trail
mix test test/version
mix test test/uuid
