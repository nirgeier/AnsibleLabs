#!/bin/bash
# Delegate to the canonical init_site.sh in .mkdocs-shared
exec "$(git rev-parse --show-toplevel)/.mkdocs-shared/init_site.sh" "$@"
