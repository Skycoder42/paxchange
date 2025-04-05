#!/bin/bash
set -exo pipefail

dart_version=$(dart --version | cut -d: -f2 | cut '-d(' -f1 | xargs)
docker build --pull	-f tool/Dockerfile -t paxchange_test:latest --build-arg "DART_VERSION=$dart_version" .
docker run --rm -it \
  -v './bin:/app/bin:ro' \
  -v './lib:/app/lib:ro' \
  -v './test/integration:/app/test/integration:ro' \
  paxchange_test:latest "$@"
