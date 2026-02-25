#!/usr/bin/env python3
"""
Generate individual .txt transcript files from the training corpus.

Piper expects each WAV file to have a matching .txt file with its transcription.
This script creates those pairs: 001.wav -> 001.txt, 002.wav -> 002.txt, etc.

Run this on your Linux training host after transferring wav_output/ from the VM.

Usage:
    python3 transcript_generator.py
    python3 transcript_generator.py ../corpus/training_corpus.txt wav_output/
"""

import os
import sys


def generate_transcripts(corpus_file, output_dir):
    os.makedirs(output_dir, exist_ok=True)

    print(f"Reading corpus: {corpus_file}")
    with open(corpus_file, "r", encoding="utf-8") as f:
        lines = [line.strip() for line in f if line.strip()]

    print(f"Found {len(lines)} lines — generating transcript files...")

    for idx, line in enumerate(lines, start=1):
        filepath = os.path.join(output_dir, f"{idx:03d}.txt")
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(line)

        if idx % 50 == 0:
            print(f"  {idx} files written...")

    print(f"\nDone. {len(lines)} transcript files written to: {output_dir}")

    print("\nSample (first 5):")
    for i in range(1, min(6, len(lines) + 1)):
        filepath = os.path.join(output_dir, f"{i:03d}.txt")
        with open(filepath) as f:
            print(f"  {i:03d}.txt: {f.read()[:60]}")


if __name__ == "__main__":
    corpus_file = sys.argv[1] if len(sys.argv) > 1 else "../corpus/training_corpus.txt"
    output_dir  = sys.argv[2] if len(sys.argv) > 2 else "wav_output"

    if not os.path.exists(corpus_file):
        print(f"Error: corpus file not found: {corpus_file}")
        print(f"Usage: {sys.argv[0]} [corpus_file] [output_dir]")
        sys.exit(1)

    generate_transcripts(corpus_file, output_dir)
    print("\nReady for Piper preprocessing.")
