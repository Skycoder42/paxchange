#!/bin/bash
set -exo pipefail

docker build --pull	-f tool/Dockerfile -t paxchange_test:latest .
docker run --rm -it paxchange_test:latest
