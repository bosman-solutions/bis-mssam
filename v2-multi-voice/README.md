# v2-multi-voice

Generalized training framework for any Microsoft SAPI voice. Adds Mike and Mary support, generates Piper-ready datasets in one pass, and solves the piper-train dependency problem with a pinned Docker image.

## Files

| File | Purpose |
|------|---------|
| `mike_mary.vbs` | Runs in Windows XP VM — generates complete datasets for Mike and Mary simultaneously |
| `Dockerfile.piper-trainer` | Pinned torch/lightning stack that actually works with piper-train |
| `build_piper_trainer.sh` | Builds the image (run once) |
| `setup_datasets.sh` | Copies dataset folders into place, downloads lessac checkpoint |
| `train_voice.sh` | Universal trainer — `./train_voice.sh <voice_name>` |
| `train_mike.sh` | Wrapper for `./train_voice.sh mike` |
| `train_mary.sh` | Wrapper for `./train_voice.sh mary` |

## Workflow

```bash
# 1. In Windows XP VM — run mike_mary.vbs
#    Produces: wav_output_mary/ and wav_output_mike/
#    Each folder has WAVs, .txt transcripts, and metadata.csv

# 2. Transfer wav_output_* to Linux, then from that directory:
./build_piper_trainer.sh    # one time only
./setup_datasets.sh

# 3. Train
./train_voice.sh mary
./train_voice.sh mike
```

## What mike_mary.vbs generates

For each voice:
- `wav_output_<voice>/001.wav` … `NNN.wav` — audio
- `wav_output_<voice>/001.txt` … `NNN.txt` — transcripts
- `wav_output_<voice>/metadata.csv` — LJSpeech-format index (`filename.wav|transcript`)

The metadata.csv is what distinguishes this from v1 — it's required by Piper's LJSpeech preprocessor and avoids the extra Python step.

## Why the Dockerfile matters

The stock NVIDIA PyTorch containers ship torch versions that silently break piper-train. The fix is documented in [piper-train Discussion #167](https://github.com/rhasspy/piper/discussions/167). `Dockerfile.piper-trainer` encodes that solution so you don't rediscover it every time.

Build once, train many times.
