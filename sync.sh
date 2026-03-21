#!/bin/bash

# --- Sync Submodules ---
# This script ensures that all git submodules are updated to their latest commits on the main branch.
git submodule add https://github.com/nirgeier/mkdocs.git .mkdocs-shared 2>&1 && git submodule status
git submodule update --init --remote --merge --force
