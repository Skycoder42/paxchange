#!/bin/bash
set -exo pipefail

exec podman run --rm -it \
  -v './bin:/app/bin:ro' \
  -v './lib:/app/lib:ro' \
  -v './tool/podman-config.json:/etc/paxchange.json:ro' \
  -v 'paxchange-container-data:/var/lib/paxchange:rw' \
  --entrypoint dart \
  paxchange_test:latest run /app/bin/paxchange.dart "$@"
