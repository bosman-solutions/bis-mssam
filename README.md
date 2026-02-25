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

## Files

| File | Description |
|------|-------------|
| `mssam_wav_generator.vbs` | VBScript that drives SAPI to batch-export WAV files from the corpus |
| `mssam_training_corpus.txt` | The training corpus — 400+ utterances covering meme phonetics, pangrams, programming vocab, numbers, punctuation, and abstract language |
| `screenshots/` | Full documented pipeline, 16 images |

---

## Reproducing This

You'll need a Windows XP VM with Microsoft Sam installed (SAPI voice index 0). Everything else follows from the script.

**1. Set up the VM**

Any QEMU/KVM or VirtualBox WinXP install will work. Confirm Sam is available via Control Panel → Speech → Text To Speech.

**2. Transfer files to the VM**

Mount an SMB share or use a shared folder to get `mssam_wav_generator.vbs` and `mssam_training_corpus.txt` into the same directory on the VM.

**3. Run the generator**

```
cscript mssam_wav_generator.vbs
```

This will create a `wav_output/` folder and generate one numbered WAV per corpus line. 444 files, ~97MB, 22kHz 16-bit mono.

**4. Transfer the dataset back to Linux**

```bash
# Mount the SMB share and copy wav_output/
cp -r /mnt/share/wav_output ~/piper/mssam_dataset
```

Pair each WAV with its transcript line — the numbered filenames map 1:1 to corpus lines.

**5. Preprocess for Piper**

```bash
python3 -m piper_train.preprocess \
  --language en-us \
  --input-dir ~/piper/mssam_dataset \
  --output-dir ~/piper/mssam_training \
  --dataset-format ljspeech \
  --single-speaker \
  --sample-rate 22050
```

**6. Train**

```bash
python3 -m piper_train \
  --dataset-dir ~/piper/mssam_training \
  --accelerator gpu \
  --checkpoint-epochs 1
```

Fine-tune from a Lessac checkpoint for best results. Training on an RTX 3080 with 444 samples runs for hours at 6000 epochs. Watch the loss values — they should decrease steadily.

**7. Deploy**

Export the checkpoint to an `.onnx` model and load it into Piper TTS. Drop it in your voice directory and point Home Assistant (or any Piper-compatible system) at it.

---

## Screenshots

The full documented pipeline lives in `/screenshots`:

| File | What it shows |
|------|---------------|
| `01-qemu-winxp-boot.png` | WinXP setup boot in QEMU/KVM |
| `02-winxp-setup-regional.png` | WinXP Professional Setup — Regional and Language Options |
| `03-winxp-setup-progress.png` | WinXP install progress |
| `04-winxp-desktop-clean.png` | WinXP desktop — Bliss wallpaper, clean install confirmed |
| `05-sapi-microsoft-sam-selected.png` | Speech Properties — Microsoft Sam selected as default voice |
| `06-device-manager-ms-sam-xp.png` | Device Manager — MS-SAM-XP hardware profile |
| `07-xp-cmd-network-test.png` | XP CMD — network connectivity test to host (ping, telnet) |
| `08-smb-share-mounted.png` | SMB share mounted from host |
| `09-wav-output-444-files.png` | wav_output folder — 444 files, 97.3MB confirmed |
| `10-piper-preprocessing-444-utterances.png` | Piper preprocessing — 444 utterances, 8 workers |
| `11-training-corpus-meme-dataset.png` | Training corpus — the meme dataset |
| `12-vbscript-sapi-batch-export.png` | VBScript generator — SAPI batch export logic |
| `13-wav-output-file-listing.png` | wav_output file listing — 444 WAVs + paired txt transcripts |
| `14-pytorch-training-rtx3080-cuda.png` | PyTorch Lightning training — RTX 3080, CUDA, loss running |
| `15-homeassistant-mssam-deployed.png` | Home Assistant Assist — Microsoft Sam deployed as voice assistant |
| `16-sapi-voice-selection-detail.png` | XP Speech Properties — Microsoft Sam voice selection detail |

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