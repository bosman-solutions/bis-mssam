# bis-mssam

Neural TTS training pipeline for Microsoft's classic SAPI voices — Sam, Mike, and Mary.

The goal was simple: these voices are a piece of internet history, and they deserved a second life. Not as nostalgia, but as actual deployable TTS voices running on modern hardware, locally, with no cloud dependency.

---

## What This Is

This repo documents a complete pipeline for training Piper TTS models from Microsoft SAPI voice output. The approach:

1. **Spin up a period-accurate Windows XP VM** (QEMU/KVM with SAPI 5.1 installed)
2. **Drive SAPI from VBScript** to batch-export the training corpus as WAV files
3. **Transfer the dataset to Linux** and preprocess it for Piper
4. **Train via PyTorch Lightning** inside a pinned Docker container, fine-tuning from a pretrained lessac checkpoint
5. **Export to ONNX** and deploy — in this case, as the default voice for a Home Assistant voice assistant

The pipeline evolved in two versions. `v1-sam/` is the original proof-of-concept for Sam. `v2-multi-voice/` generalizes it into a reusable framework for any SAPI voice, with a Dockerfile that solves the dependency hell that makes piper-train painful to set up.

---

## Repository Structure

```
bis-mssam/
├── corpus/
│   └── training_corpus.txt       # shared training data — ~440 lines
├── v1-sam/
│   ├── mssam_wav_generator.vbs   # SAPI driver for Sam (Windows XP VM)
│   └── transcript_generator.py  # pairs WAVs with .txt transcripts (Linux)
└── v2-multi-voice/
    ├── mike_mary.vbs              # dual-voice SAPI driver — WAV + txt + metadata.csv
    ├── Dockerfile.piper-trainer   # pinned torch/lightning/phonemize stack
    ├── build_piper_trainer.sh     # build the image (run once)
    ├── setup_datasets.sh          # move datasets into place, download checkpoint
    ├── train_voice.sh             # universal trainer — ./train_voice.sh <name>
    ├── train_mike.sh              # convenience wrapper
    └── train_mary.sh              # convenience wrapper
```

---

## The Corpus

`corpus/training_corpus.txt` is the shared training dataset used for all voices. It's ~440 lines covering:

- **Phonetic coverage** — pangrams, alphabet run, numbers, punctuation names
- **Internet culture** — classic memes and copypasta from the era these voices lived in
- **Technical vocabulary** — programming terms, system messages, Windows UI strings
- **General language** — conversational phrases, abstract concepts, Latin loanwords

The corpus was designed to give the model broad phoneme coverage while staying true to the context where these voices were actually heard.

---

## Prerequisites

### Windows XP VM (for dataset generation)
- QEMU/KVM with a Windows XP SP3 image
- [Microsoft SAPI 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=10121) (SpeechSDK51.exe)
- For Mike and Mary: Microsoft TTS voices (msttss22L.exe or similar)

### Linux training host
- Docker with NVIDIA GPU support (`nvidia-container-toolkit`)
- CUDA 12.1 compatible GPU (tested on RTX 3080)
- ~10GB free disk space for training artifacts

---

## Quickstart

### v1 — Microsoft Sam

1. Set up your Windows XP VM and install SAPI 5.1
2. Copy `v1-sam/` and `corpus/` into the VM
3. Run `mssam_wav_generator.vbs` — generates `wav_output/001.wav` through `NNN.wav`
4. Transfer `wav_output/` to your Linux host
5. Run `python3 transcript_generator.py` to generate matching `.txt` files
6. Follow Piper's standard preprocessing and training steps

### v2 — Mike & Mary (and any SAPI voice)

**In the Windows XP VM:**
```
1. Install SAPI 5.1 + Microsoft TTS voices
2. Run mike_mary.vbs
   — generates wav_output_mary/ and wav_output_mike/
   — each folder contains WAVs, matching .txt files, and metadata.csv
3. Transfer both wav_output_* folders to your Linux host
```

**On the Linux training host:**
```bash
# One-time setup
cd v2-multi-voice/
./build_piper_trainer.sh         # build the Docker image (~15 min)

# Move datasets into place and download the lessac checkpoint
./setup_datasets.sh              # run from where the wav_output_* folders are

# Train
./train_voice.sh mary
./train_voice.sh mike
# or: ./train_mary.sh / ./train_mike.sh
```

Output for each voice:
```
~/piper/ms<voice>.onnx
~/piper/ms<voice>.onnx.json
~/piper/test_<voice>.wav         # smoke test output
```

---

## The Dockerfile

The most practically useful piece of this repo is probably `v2-multi-voice/Dockerfile.piper-trainer`.

Piper's training setup has a dependency conflict: the NVIDIA PyTorch base images ship torch versions that break `piper-train`, and the fix isn't documented clearly. After working through [piper-train Discussion #167](https://github.com/rhasspy/piper/discussions/167), the working stack is:

```
torch==2.1.0+cu121
torchvision==0.16.0+cu121
torchaudio==2.1.0+cu121
pytorch-lightning==1.8.6
torchmetrics==0.11.4
piper-phonemize==1.1.0   # needs Python 3.10 wheel — newer versions don't have it
```

Building this image once means you're not solving dependency conflicts on every training run.

---

## Notes

- The `.onnx` model files are not included — they contain output derived from proprietary Microsoft voices. Train your own.
- The lessac checkpoint (`epoch=2164-step=1355540.ckpt`) used as the training base is downloaded automatically by `setup_datasets.sh` from the [rhasspy/piper-checkpoints](https://huggingface.co/datasets/rhasspy/piper-checkpoints) dataset on Hugging Face.
- Training takes several hours on an RTX 3080. Watch loss values stabilize — you don't need to run all 6000 epochs.
- The smoke test line is `my roflcopter goes soi soi soi soi soi`. If it sounds right, it's right.

---

## Deployment

The trained models deploy anywhere Piper is supported. This pipeline's output runs as the default voice assistant on a Home Assistant instance via Wyoming Protocol.

```bash
# Run Piper with a trained model
echo "hello world" | piper -m ~/piper/msmary.onnx --output_file out.wav
```

---

*Sam deserved a second life.*
