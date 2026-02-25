# bis-mssam

**Recreating Microsoft Sam as a neural TTS voice model — from a Windows XP VM to a live Home Assistant assistant.**

---

## The Goal

Microsoft Sam doesn't exist as a modern TTS model. He exists as a SAPI voice locked inside Windows XP. The only way to get clean Sam audio is to go back in time and ask him nicely.

This project documents the full pipeline: acquiring the dataset from the original source, preprocessing it for neural training, training a Piper TTS model on local hardware, and deploying it as a production voice assistant.

No cloud. No shortcuts. Every stage understood before moving to the next.

---

## The Pipeline

### 1. Dataset Acquisition — Windows XP VM

Sam lives in XP. So XP it is.

Spun up a Windows XP Professional VM in QEMU/KVM. Configured the SAPI Text-to-Speech engine with Microsoft Sam as the active voice. Wrote a VBScript generator (`mssam_wav_generator.v2.vbs`) to drive the SAPI interface programmatically — reading lines from a corpus file, invoking `SAPI.SpFileStream` at 22kHz 16-bit mono, and batch-exporting each utterance as a numbered WAV file.

444 utterances. Silent generation, no popups, padded filenames for clean dataset indexing.

### 2. The Corpus

The training corpus is curated internet — memes, catchphrases, phonetically varied nonsense that pushes Sam's voice into its full range. "All your base are belong to us." "The cake is a lie." "My roflcopter goes soi soi soi soi."

This wasn't arbitrary. Sam's voice has specific phonetic quirks. The corpus was designed to capture them.

### 3. Dataset Transfer

Transferred the WAV output folder (444 files, ~97MB) from the XP VM to the Linux training host (Balthazar) over SMB. Verified file integrity and count before proceeding.

### 4. Preprocessing

```bash
python3 -m piper_train.preprocess \
  --language en-us \
  --input-dir ~/piper/mssam_dataset \
  --output-dir ~/piper/mssam_training \
  --dataset-format ljspeech \
  --single-speaker \
  --sample-rate 22050
```

Piper's preprocessor confirmed: 444 utterances, 8 workers, single-speaker dataset config written.

### 5. Training

PyTorch Lightning on an RTX 3080 (10GB VRAM). CUDA 12.9. Fine-tuned from a Lessac checkpoint. GPU pegged at ~51% utilization, 9386MB memory allocated to the training process.

```
LOCAL_RANK: 0 - CUDA_VISIBLE_DEVICES: [0]
Restored all states from the checkpoint file
Number of training batches: 14
```

Watched the loss values decrease. That's Sam's voice being learned.

### 6. Deployment

The trained model was loaded into Piper TTS and deployed as a Home Assistant voice assistant — Microsoft Sam, starred as default, running entirely locally on the home network alongside Amy and a full local assistant configuration.

Sam now announces when the washing machine is done.

---

## Screenshots

The full documented pipeline lives in `/screenshots`:

| # | What it shows |
|---|---------------|
| 01 | WinXP setup boot in QEMU/KVM |
| 02 | WinXP Professional Setup — Regional and Language Options |
| 03 | WinXP install progress |
| 04 | WinXP desktop — Bliss wallpaper, clean install confirmed |
| 05 | Speech Properties — Microsoft Sam selected as default voice |
| 06 | Device Manager — MS-SAM-XP hardware profile |
| 07 | XP CMD — network connectivity test to host (ping, telnet) |
| 08 | SMB share mounted from host |
| 09 | wav_output folder — 444 files, 97.3MB confirmed |
| 10 | Piper preprocessing — 444 utterances, 8 workers |
| 11 | Training corpus — the meme dataset |
| 12 | VBScript generator — SAPI batch export logic |
| 13 | wav_output file listing — 444 WAVs + paired txt transcripts |
| 14 | PyTorch Lightning training — RTX 3080, CUDA, loss running |
| 15 | Home Assistant Assist — Microsoft Sam deployed as voice assistant |
| 16 | XP Speech Properties — Microsoft Sam voice selection detail |

---

## Stack

- **VM:** QEMU/KVM, Windows XP Professional
- **Dataset generation:** VBScript, Windows SAPI (`SAPI.SpFileStream`)
- **Transfer:** SMB (Samba)
- **Preprocessing:** Piper TTS training pipeline, LJSpeech format
- **Training:** PyTorch Lightning, CUDA 12.9, RTX 3080
- **Deployment:** Piper TTS, Home Assistant Assist

---

## Why

Because understanding a pipeline means building it from the source. Anyone can fine-tune a model from a HuggingFace checkpoint. Fewer people spin up a period-accurate VM to extract a 2001 voice engine's output as a training dataset.

Also Sam deserved a second life.

---

*Part of the [Bosman intelligent Solutions](https://github.com/bosman-solutions) portfolio.*