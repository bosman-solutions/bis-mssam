#!/bin/bash
# Train any voice with Piper.
# Uses the pre-built piper-trainer:working image (run build_piper_trainer.sh first).
#
# Usage: ./train_voice.sh <voice_name>
#
# Expects:
#   ~/piper/<voice>_dataset/wav_output/   — WAVs + metadata.csv
#   ~/piper/epoch=2164-step=1355540.ckpt  — lessac checkpoint
#   Docker image: piper-trainer:working
#
# Output:
#   ~/piper/ms<voice>.onnx
#   ~/piper/ms<voice>.onnx.json
#   ~/piper/test_<voice>.wav

set -e

if [ -z "$1" ]; then
    echo "Usage: ./train_voice.sh <voice_name>"
    echo "  e.g. ./train_voice.sh mary"
    echo "       ./train_voice.sh mike"
    exit 1
fi

VOICE="$1"
PIPER_BASE="$HOME/piper"
DATASET_DIR="$PIPER_BASE/${VOICE}_dataset"
TRAINING_DIR="$PIPER_BASE/${VOICE}_training"
CHECKPOINT="$PIPER_BASE/epoch=2164-step=1355540.ckpt"

if [ ! -d "$DATASET_DIR/wav_output" ]; then
    echo "ERROR: Dataset not found at $DATASET_DIR/wav_output/"
    echo "Run setup_datasets.sh first."
    exit 1
fi
if [ ! -f "$DATASET_DIR/wav_output/metadata.csv" ]; then
    echo "ERROR: metadata.csv not found in $DATASET_DIR/wav_output/"
    exit 1
fi
if [ ! -f "$CHECKPOINT" ]; then
    echo "ERROR: Checkpoint not found at $CHECKPOINT"
    echo "Run setup_datasets.sh to download it."
    exit 1
fi
if ! docker image inspect piper-trainer:working >/dev/null 2>&1; then
    echo "ERROR: piper-trainer:working image not found."
    echo "Run build_piper_trainer.sh first."
    exit 1
fi

mkdir -p "$TRAINING_DIR"

echo "======================================="
echo "Training: $VOICE"
echo "======================================="
echo "Dataset:    $DATASET_DIR/wav_output/"
echo "Output:     $TRAINING_DIR/"
echo "Checkpoint: $CHECKPOINT"
echo ""
echo "GPU will run hot. This takes several hours."
echo ""
read -p "Press Enter to start, Ctrl+C to cancel..."

docker run --gpus all --ipc=host \
    --ulimit memlock=-1 --ulimit stack=67108864 \
    -v "$PIPER_BASE":/workspace/piper \
    piper-trainer:working bash -c "

set -e

echo '--- Preprocessing ---'
cd /workspace/piper/src/python
python3 -m piper_train.preprocess \
    --language en-us \
    --input-dir  /workspace/piper/${VOICE}_dataset/wav_output \
    --output-dir /workspace/piper/${VOICE}_training \
    --dataset-format ljspeech \
    --single-speaker \
    --sample-rate 22050

echo ''
echo '--- Training (watch loss stabilize) ---'
python3 -m piper_train \
    --dataset-dir /workspace/piper/${VOICE}_training \
    --accelerator gpu \
    --devices 1 \
    --batch-size 32 \
    --validation-split 0.0 \
    --num-test-examples 0 \
    --max_epochs 6000 \
    --resume_from_checkpoint /workspace/piper/epoch=2164-step=1355540.ckpt \
    --checkpoint-epochs 100 \
    --precision 32

echo ''
echo '--- Exporting to ONNX ---'
LATEST=\$(ls -t /workspace/piper/${VOICE}_training/lightning_logs/version_0/checkpoints/*.ckpt | head -1)
echo \"Checkpoint: \$LATEST\"

python3 -m piper_train.export_onnx \
    \"\$LATEST\" \
    /workspace/piper/ms${VOICE}.onnx

cp /workspace/piper/${VOICE}_training/config.json /workspace/piper/ms${VOICE}.onnx.json
sed -i 's/\"dataset\": \"[^\"]*\"/\"dataset\": \"ms${VOICE}\"/' /workspace/piper/ms${VOICE}.onnx.json

echo ''
echo '--- Smoke test ---'
echo 'my roflcopter goes soi soi soi soi soi' | \
    piper -m /workspace/piper/ms${VOICE}.onnx \
          --output_file /workspace/piper/test_${VOICE}.wav

echo ''
echo '======================================='
echo '${VOICE} training complete.'
echo '======================================='
echo \"  ~/piper/ms${VOICE}.onnx\"
echo \"  ~/piper/ms${VOICE}.onnx.json\"
echo \"  ~/piper/test_${VOICE}.wav\"
"

docker container prune -f

echo ""
echo "Done. Output in: $PIPER_BASE/"
