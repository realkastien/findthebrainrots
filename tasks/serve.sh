#!/bin/bash

# Build network remotes with blink and then start rojo server
echo "Building network remotes..."
blink network/remotes/main.blink

echo "Starting rojo server..."
rojo serve
