#!/bin/bash
set -e

cd "$SCRIPT_DIR"

docker compose logs -f "$@"
