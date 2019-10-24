#!/usr/bin/env bash

if [[ -f /.dockerenv ]]; then
  hadolint Dockerfile
else
  docker run \
    -v $(pwd):/mnt/workspace \
    -w /mnt/workspace \
    hadolint/hadolint:latest \
    hadolint Dockerfile
fi
