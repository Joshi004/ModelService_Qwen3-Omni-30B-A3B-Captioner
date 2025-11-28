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

# Media server configuration - serves both videos/ and audios/ subdirectories
MEDIA_DIR="/home/naresh/datasets"
MEDIA_PORT=8080

# Check if port 8080 is already in use
if lsof -Pi :$MEDIA_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}HTTP server already running on port $MEDIA_PORT - reusing existing server${NC}"
    echo "  Media files accessible at: http://localhost:$MEDIA_PORT/"
else
    echo -e "${GREEN}Starting HTTP server for media files...${NC}"
    echo "  Directory: $MEDIA_DIR"
    echo "  Port: $MEDIA_PORT"
    echo "  Serving: videos/, audios/, and other subdirectories"
    
    # Check if media directory exists
    if [ ! -d "$MEDIA_DIR" ]; then
        echo -e "${YELLOW}Warning: Directory $MEDIA_DIR does not exist. Creating it...${NC}"
        mkdir -p "$MEDIA_DIR"
    fi
    
    # Start Python HTTP server in background with nohup for proper detachment
    cd "$MEDIA_DIR"
    nohup python3 -m http.server $MEDIA_PORT > /tmp/media_server.log 2>&1 &
    MEDIA_SERVER_PID=$!
    echo $MEDIA_SERVER_PID > /tmp/media_server.pid
    echo -e "${GREEN}HTTP server started with PID: $MEDIA_SERVER_PID${NC}"
    echo "  Video URLs: http://localhost:$MEDIA_PORT/videos/<filename>"
    echo "  Audio URLs: http://localhost:$MEDIA_PORT/audios/<filename>"
    
    # Return to service directory
    cd /home/naresh/qwen3-captioner-service
    
    # Give the HTTP server a moment to start and verify it's running
    sleep 3
    
    # Verify the server is actually running
    if lsof -Pi :$MEDIA_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${GREEN}HTTP server verified running on port $MEDIA_PORT${NC}"
    else
        echo -e "${YELLOW}Warning: HTTP server may not have started properly. Check /tmp/media_server.log${NC}"
        if [ -f /tmp/media_server.log ]; then
            echo "  Last few lines of server log:"
            tail -5 /tmp/media_server.log | sed 's/^/    /'
        fi
    fi
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



