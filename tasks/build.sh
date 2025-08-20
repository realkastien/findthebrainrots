#!/bin/bash

# Generate sourcemap and then build network remotes
echo "Generating sourcemap..."
rojo sourcemap -o sourcemap.json

echo "Building network remotes..."
blink network/remotes/main.blink
