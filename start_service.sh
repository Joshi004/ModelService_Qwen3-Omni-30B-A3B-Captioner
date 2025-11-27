#!/bin/bash

# Qwen3-Omni Audio Captioner Service Startup Script
# This script starts the vLLM server for Qwen3-Omni-30B-A3B-Captioner model

# Exit on any error
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Qwen3-Omni Audio Captioner Service...${NC}"

# Set environment variables
export VLLM_USE_V1=0  # Required for Qwen3-Omni compatibility

# Set CUDA environment variables
export CUDA_HOME=/usr/local/cuda-12.9
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Activate virtual environment
source /home/naresh/venvs/qwen3-captioner-service/bin/activate

echo -e "${YELLOW}Virtual environment activated${NC}"

# Model configuration
MODEL_PATH="/home/naresh/models/qwen3-omni-30b-captioner"
PORT=8003
HOST="0.0.0.0"
DTYPE="bfloat16"
MAX_MODEL_LEN=32768  # For ~30s audio clips (optimal for Captioner model)
TENSOR_PARALLEL_SIZE=2  # Using 2x H100 GPUs
GPU_MEMORY_UTIL=0.95
MAX_NUM_SEQS=8

# Video/Audio server configuration
VIDEO_DIR="/home/naresh/datasets/videos"
VIDEO_PORT=8080

# Check if port 8080 is already in use
if lsof -Pi :$VIDEO_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}HTTP server already running on port $VIDEO_PORT - reusing existing server${NC}"
    echo "  Media files accessible at: http://localhost:$VIDEO_PORT/"
else
    echo -e "${GREEN}Starting HTTP server for audio/video files...${NC}"
    echo "  Directory: $VIDEO_DIR"
    echo "  Port: $VIDEO_PORT"
    
    # Check if directory exists
    if [ ! -d "$VIDEO_DIR" ]; then
        echo -e "${YELLOW}Warning: Directory $VIDEO_DIR does not exist. Creating it...${NC}"
        mkdir -p "$VIDEO_DIR"
    fi
    
    # Start Python HTTP server in background
    cd "$VIDEO_DIR"
    python3 -m http.server $VIDEO_PORT > /tmp/video_server.log 2>&1 &
    VIDEO_SERVER_PID=$!
    echo $VIDEO_SERVER_PID > /tmp/video_server.pid
    echo -e "${GREEN}HTTP server started with PID: $VIDEO_SERVER_PID${NC}"
    echo "  Media URLs: http://localhost:$VIDEO_PORT/<filename>"
    
    # Return to service directory
    cd /home/naresh/qwen3-captioner-service
    
    # Give the HTTP server a moment to start
    sleep 2
fi

echo ""

# Create logs directory if it doesn't exist
mkdir -p /home/naresh/qwen3-captioner-service/logs

echo -e "${GREEN}Starting vLLM server with following configuration:${NC}"
echo "  Model: $MODEL_PATH"
echo "  Port: $PORT"
echo "  Tensor Parallel Size: $TENSOR_PARALLEL_SIZE GPUs"
echo "  Max Model Length: $MAX_MODEL_LEN tokens"
echo "  GPU Memory Utilization: ${GPU_MEMORY_UTIL}"
echo "  Note: This is an audio captioning model (audio input only, text output)"
echo ""
echo -e "${YELLOW}Service will be accessible via SSH tunnel at localhost:$PORT${NC}"
echo -e "${YELLOW}Logs will be saved to: /home/naresh/qwen3-captioner-service/logs/service.log${NC}"
echo ""

# Start vLLM server with logging (output to both console and log file)
vllm serve "$MODEL_PATH" \
  --port "$PORT" \
  --host "$HOST" \
  --dtype "$DTYPE" \
  --max-model-len "$MAX_MODEL_LEN" \
  --allowed-local-media-path / \
  --tensor-parallel-size "$TENSOR_PARALLEL_SIZE" \
  --gpu-memory-utilization "$GPU_MEMORY_UTIL" \
  --trust-remote-code \
  --max-num-seqs "$MAX_NUM_SEQS" \
  2>&1 | tee /home/naresh/qwen3-captioner-service/logs/service.log



