#!/usr/bin/env bash
set -e
docker build --no-cache --platform=linux/amd64 -t registry.layer-8.dev:44443/probler/layer8-webui:latest .
docker push registry.layer-8.dev:44443/probler/layer8-webui:latest
