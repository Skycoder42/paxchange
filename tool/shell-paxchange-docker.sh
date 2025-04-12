#!/bin/bash
set -exo pipefail

exec docker run --rm -it \
  -v './bin:/app/bin:ro' \
  -v './lib:/app/lib:ro' \
  -v './tool/docker-config.json:/etc/paxchange.json:ro' \
  -v 'paxchange-container-data:/var/lib/paxchange:rw' \
  --entrypoint /bin/bash \
  paxchange_test:latest
