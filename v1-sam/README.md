# v1-sam

The original Microsoft Sam training pipeline. Proof of concept for the whole project.

## Files

**`mssam_wav_generator.vbs`** — Runs inside a Windows XP VM. Reads `../corpus/training_corpus.txt` line by line, calls SAPI to speak each line, and writes the output to `wav_output/001.wav`, `002.wav`, etc. Voice index 0 on a stock SAPI 5.1 install is Sam.

**`transcript_generator.py`** — Runs on Linux after transferring `wav_output/`. Creates a matching `.txt` file for each WAV so Piper knows what was said in each file. Run before preprocessing.

## Usage

```
[Windows XP VM]
1. Install SpeechSDK51.exe (SAPI 5.1)
2. Run mssam_wav_generator.vbs
3. Transfer wav_output/ to Linux

[Linux]
4. python3 transcript_generator.py
5. Proceed with standard Piper preprocessing and training
```

See the root README for full context, or `v2-multi-voice/` for the generalized version with a Docker-based training pipeline.
