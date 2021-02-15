#!/bin/sh

nix-shell -p nodejs --run "npx prettier --write --prose-wrap always README.md INTERNALS.md"
