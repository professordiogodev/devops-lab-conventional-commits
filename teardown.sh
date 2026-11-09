#!/usr/bin/env bash
# Removes what this lab created. Run with: ./teardown.sh
cd "$(dirname "$0")" && rm -rf sandbox
echo "Lab environment removed."
