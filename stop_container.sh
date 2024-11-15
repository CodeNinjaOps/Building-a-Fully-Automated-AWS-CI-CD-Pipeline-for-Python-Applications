#!/bin/bash

# Stop the container
docker stop my-app || true

# Optionally, remove the container
docker rm my-app || true