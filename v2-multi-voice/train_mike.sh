#!/bin/bash
# Convenience wrapper — trains Microsoft Mike.
# Equivalent to: ./train_voice.sh mike

exec "$(dirname "$0")/train_voice.sh" mike
