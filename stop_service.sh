#!/bin/bash

# Qwen3-Omni Audio Captioner Service Stop Script
# This script stops the vLLM server

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Stopping Qwen3-Omni Audio Captioner Service...${NC}"

# Find and kill vllm processes on port 8003
VLLM_PIDS=$(lsof -ti:8003 2>/dev/null)

if [ -z "$VLLM_PIDS" ]; then
    # Also try finding by process name
    VLLM_PIDS=$(pgrep -f "vllm serve.*qwen3-omni-30b-captioner")
fi

if [ -z "$VLLM_PIDS" ]; then
    echo -e "${RED}No vLLM Audio Captioner service found running on port 8003.${NC}"
    exit 0
fi

echo "Found vLLM processes: $VLLM_PIDS"

for PID in $VLLM_PIDS; do
    echo "Stopping process $PID..."
    kill -15 "$PID"
done

echo -e "${GREEN}Waiting for graceful shutdown...${NC}"
sleep 5

# Force kill if still running
REMAINING_PIDS=$(lsof -ti:8003 2>/dev/null)
if [ -z "$REMAINING_PIDS" ]; then
    REMAINING_PIDS=$(pgrep -f "vllm serve.*qwen3-omni-30b-captioner")
fi

if [ -n "$REMAINING_PIDS" ]; then
    echo -e "${RED}Force killing remaining processes...${NC}"
    for PID in $REMAINING_PIDS; do
        kill -9 "$PID"
    done
fi

echo -e "${GREEN}Service stopped successfully.${NC}"








