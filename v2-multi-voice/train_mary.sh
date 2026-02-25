#!/bin/bash
# Convenience wrapper — trains Microsoft Mary.
# Equivalent to: ./train_voice.sh mary

exec "$(dirname "$0")/train_voice.sh" mary
