#!/usr/bin/env bash
set -e
docker build --no-cache --platform=linux/amd64 -t saichler/book:latest .
docker push saichler/book:latest
