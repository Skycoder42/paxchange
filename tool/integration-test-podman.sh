#!/bin/bash
set -exo pipefail

dart_version=$(dart --version | cut -d: -f2 | cut '-d(' -f1 | xargs)
podman build --pull	-f tool/Dockerfile -t paxchange_test:latest --build-arg "DART_VERSION=$dart_version" .
podman run --rm -it \
  -v './bin:/app/bin:ro' \
  -v './lib:/app/lib:ro' \
  -v './test/integration:/app/test/integration:ro' \
  paxchange_test:latest "$@"
