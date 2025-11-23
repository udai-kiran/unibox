#!/bin/bash
set -e

# If no command is provided, default to zsh
if [ $# -eq 0 ]; then
    exec /bin/zsh
else
    exec "$@"
fi
