#!/bin/bash
# Set up training datasets on the Linux host.
#
# Run this after transferring wav_output_mary/ and wav_output_mike/
# from the Windows VM. Run it from the directory containing those folders.
#
# Also downloads the lessac checkpoint if not already present.

set -e

PIPER_BASE="$HOME/piper"

echo "======================================="
echo "Setting up Mike & Mary Datasets"
echo "======================================="

for voice in mary mike; do
    if [ ! -d "wav_output_${voice}" ]; then
        echo "ERROR: wav_output_${voice}/ not found."
        echo "Transfer both wav_output_* folders from the Windows VM first."
        exit 1
    fi
    if [ ! -f "wav_output_${voice}/metadata.csv" ]; then
        echo "ERROR: wav_output_${voice}/metadata.csv missing."
        echo "Make sure mike_mary.vbs completed successfully."
        exit 1
    fi
done

mkdir -p \
    "$PIPER_BASE/mary_dataset/wav_output" \
    "$PIPER_BASE/mike_dataset/wav_output" \
    "$PIPER_BASE/mary_training" \
    "$PIPER_BASE/mike_training"

for voice in mary mike; do
    echo "Copying ${voice} dataset..."
    cp -v "wav_output_${voice}/"* "$PIPER_BASE/${voice}_dataset/wav_output/"
    count=$(ls "$PIPER_BASE/${voice}_dataset/wav_output/"*.wav 2>/dev/null | wc -l)
    echo "  ${count} WAV files copied"
done

CHECKPOINT="$PIPER_BASE/epoch=2164-step=1355540.ckpt"
if [ ! -f "$CHECKPOINT" ]; then
    echo ""
    echo "Downloading lessac medium checkpoint (~400MB)..."
    wget -P "$PIPER_BASE" \
        https://huggingface.co/datasets/rhasspy/piper-checkpoints/resolve/main/en/en_US/lessac/medium/epoch=2164-step=1355540.ckpt
    echo "Checkpoint downloaded."
else
    echo "Checkpoint already present, skipping."
fi

echo ""
echo "======================================="
echo "Setup complete."
echo "======================================="
echo ""
echo "Ready to train:"
echo "  ./train_voice.sh mary"
echo "  ./train_voice.sh mike"
