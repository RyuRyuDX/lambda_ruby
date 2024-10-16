#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /kinkyu_bot/tmp/pids/server.pid

# Install JS dependencies
yarn install

# Compile assets
yarn build
yarn build:css

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
