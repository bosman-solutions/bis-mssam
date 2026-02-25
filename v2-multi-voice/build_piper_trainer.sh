#!/bin/bash
# Build the piper-trainer image.
# Run this once — the image is reused for every subsequent training session.
# Takes 15-20 minutes on first build.

set -e

echo "======================================="
echo "Building piper-trainer:working"
echo "======================================="
echo ""
echo "This pulls NVIDIA PyTorch 23.10-py3 and installs:"
echo "  torch 2.1.0+cu121 / lightning 1.8.6 / piper-phonemize 1.1.0"
echo "  + clones and builds piper from source"
echo ""
echo "Only needs to run once. Ctrl+C to cancel."
echo ""
read -p "Press Enter to start..."

docker build -f Dockerfile.piper-trainer -t piper-trainer:working .

echo ""
echo "======================================="
echo "Done — image: piper-trainer:working"
echo "======================================="
echo ""
echo "Next:"
echo "  ./setup_datasets.sh    — copy WAV folders and download checkpoint"
echo "  ./train_voice.sh mary  — train a voice"
