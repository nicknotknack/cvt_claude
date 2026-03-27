#!/bin/bash
# Launches Claude Code in a tmux session with Agent Teams task

SESSION="cryptovision-agents"

# Kill existing session if any
tmux kill-session -t $SESSION 2>/dev/null

# Create new session and run claude with the task
tmux new-session -s $SESSION \; \
  send-keys "cd /Users/nick/Projects/CryptoVision && claude --print ''" Enter \; \
  send-keys "" ""

# Actually just open claude interactively so user can type the prompt
tmux new-session -s $SESSION "cd /Users/nick/Projects/CryptoVision && claude" \; \
  attach-session -t $SESSION
