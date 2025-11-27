# Qwen3-Omni Audio Captioner Service

A production-ready service for running the Qwen3-Omni-30B-A3B-Captioner model using vLLM's built-in API server.

## Overview

This service deploys the Qwen3-Omni-30B-A3B-Captioner model, a specialized audio captioning model fine-tuned from Qwen3-Omni-30B-A3B-Instruct. It generates detailed, low-hallucination captions for arbitrary audio inputs without requiring any text prompts.

### Model Information
- **Model**: Qwen3-Omni-30B-A3B-Captioner
- **Location**: `/home/naresh/models/qwen3-omni-30b-captioner/`
- **Capabilities**: Audio-only input, text-only output
- **Specialty**: Fine-grained audio analysis and captioning
- **Optimal Audio Length**: ≤ 30 seconds for best detail perception

### Hardware Configuration
- **GPUs**: 2x NVIDIA H100 (80GB each)
- **Tensor Parallelism**: Enabled across both GPUs
- **Total GPU Memory**: 160GB

## Key Features

The Captioner model excels at:

### Speech Understanding
- Multiple speaker emotion identification
- Multilingual expression recognition
- Layered intention detection
- Cultural context perception
- Implicit information understanding

### Non-Speech Audio
- Sound recognition and analysis
- Ambient atmosphere description
- Dynamic audio detail capture
- Film and media sound effect analysis

## Quick Start

### 1. Start the Service

```bash
cd /home/naresh/qwen3-captioner-service
./start_service.sh
```

The service will start on **Port 8003** with:
- Max model length: 32,768 tokens (suitable for ~30s audio)
- GPU memory utilization: 95%
- Tensor parallel size: 2 (both GPUs)
- Max concurrent sequences: 8

### 2. Test the Service

#### Using the Test Client

```bash
# Test with the built-in example audio
python test_client.py

# Or use your own audio URL
python test_client.py "https://example.com/audio.mp3"
```

#### Using curl

```bash
curl http://localhost:8003/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{
      "role": "user",
      "content": [
        {"type": "audio_url", "audio_url": {"url": "https://qianwen-res.oss-cn-beijing.aliyuncs.com/Qwen3-Omni/cookbook/caption2.mp3"}}
      ]
    }],
    "temperature": 0.6,
    "top_p": 0.95,
    "top_k": 20,
    "max_tokens": 16384
  }'
```

### 3. Stop the Service

```bash
./stop_service.sh
```

## SSH Tunneling (Local Access)

To access the service from your local machine via SSH tunnel:

### Setup SSH Tunnel

```bash
# From your local machine
ssh -L 8003:localhost:8003 user@remote-server

# Keep this terminal open while using the service
```

Now you can access the service at `http://localhost:8003` from your local machine.

### Test from Local Machine

```bash
# Example curl request
curl http://localhost:8003/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{
      "role": "user",
      "content": [
        {"type": "audio_url", "audio_url": {"url": "https://example.com/audio.mp3"}}
      ]
    }],
    "temperature": 0.6,
    "top_p": 0.95,
    "top_k": 20,
    "max_tokens": 16384
  }'
```

## API Usage

### Endpoint

```
POST http://localhost:8003/v1/chat/completions
```

### Request Format

**Important**: This Captioner model does NOT accept text prompts. It automatically generates captions from audio input.

```json
{
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "audio_url",
          "audio_url": {
            "url": "https://example.com/audio.mp3"
          }
        }
      ]
    }
  ],
  "temperature": 0.6,
  "top_p": 0.95,
  "top_k": 20,
  "max_tokens": 16384
}
```

### Supported Audio Formats

- MP3
- WAV
- FLAC
- M4A
- OGG
- Other common audio formats

### Response Format

```json
{
  "id": "cmpl-...",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "/home/naresh/models/qwen3-omni-30b-captioner",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Detailed caption of the audio content..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 120,
    "completion_tokens": 350,
    "total_tokens": 470
  }
}
```

## Python Client Example

```python
import requests
import json

def caption_audio(audio_url, base_url="http://localhost:8003"):
    """Generate caption for audio using the Qwen3-Omni Captioner service."""
    
    response = requests.post(
        f"{base_url}/v1/chat/completions",
        headers={"Content-Type": "application/json"},
        json={
            "messages": [{
                "role": "user",
                "content": [
                    {"type": "audio_url", "audio_url": {"url": audio_url}}
                ]
            }],
            "temperature": 0.6,
            "top_p": 0.95,
            "top_k": 20,
            "max_tokens": 16384
        }
    )
    
    response.raise_for_status()
    result = response.json()
    return result["choices"][0]["message"]["content"]

# Usage
caption = caption_audio("https://example.com/audio.mp3")
print(caption)
```

## Configuration

### Environment Variables

Located in `config.env`:

```bash
# Required for Qwen3-Omni compatibility
export VLLM_USE_V1=0

# Model settings
MODEL_PATH="/home/naresh/models/qwen3-omni-30b-captioner"
PORT=8003
DTYPE="bfloat16"

# Performance
MAX_MODEL_LEN=32768      # Suitable for ~30s audio
TENSOR_PARALLEL_SIZE=2   # Number of GPUs
GPU_MEMORY_UTIL=0.95     # GPU memory utilization
MAX_NUM_SEQS=8          # Concurrent sequences

# Generation
TEMPERATURE=0.6
TOP_P=0.95
TOP_K=20
MAX_TOKENS=16384
```

## Service Management

### Check Service Status

```bash
# Check if service is running
curl http://localhost:8003/health

# Check vLLM processes
ps aux | grep vllm | grep 8003
```

### View Logs

```bash
# View logs in real-time
tail -f /home/naresh/qwen3-captioner-service/logs/service.log

# Search for errors
grep -i error /home/naresh/qwen3-captioner-service/logs/service.log
```

### GPU Monitoring

```bash
# Monitor GPU usage
watch -n 1 nvidia-smi

# Or use
nvtop  # If installed
```

## Troubleshooting

### Service Won't Start

1. **Check GPU availability**
   ```bash
   nvidia-smi
   ```

2. **Verify virtual environment**
   ```bash
   source /home/naresh/venvs/qwen3-captioner-service/bin/activate
   which vllm
   ```

3. **Check model path**
   ```bash
   ls -la /home/naresh/models/qwen3-omni-30b-captioner/
   ```

### Out of Memory Errors

1. Reduce `MAX_MODEL_LEN` to 16384
2. Reduce `GPU_MEMORY_UTIL` to 0.90
3. Reduce `MAX_NUM_SEQS` to 4
4. Use shorter audio clips (≤15 seconds)

### Connection Refused

1. Ensure service is running: `ps aux | grep vllm | grep 8003`
2. Check port availability: `netstat -tuln | grep 8003`
3. Verify SSH tunnel is active (if accessing remotely)

### Poor Caption Quality

1. **Audio too long**: Keep audio ≤ 30 seconds for optimal detail
2. **Audio quality**: Ensure audio is clear and not heavily compressed
3. **Multiple sources**: Very complex mixed audio may reduce detail

## Performance Tips

1. **Optimal Audio Length**: Best results with audio clips ≤ 30 seconds
2. **Batch Processing**: Process multiple audio files sequentially
3. **GPU Utilization**: Monitor with `nvidia-smi` to ensure both GPUs are utilized
4. **Audio Quality**: Higher quality audio produces better captions

## Model Capabilities

### What This Model Does Well

- **Speech Analysis**: Emotion, intention, multilingual content
- **Sound Recognition**: Environmental sounds, music, effects
- **Detailed Descriptions**: Comprehensive audio content analysis
- **Low Hallucination**: Fine-tuned for accurate captioning

### What This Model Does NOT Do

- ❌ Accept text prompts (auto-generates captions)
- ❌ Process video visual content (audio only)
- ❌ Generate audio output (text only)
- ❌ Handle very long audio (>30s may reduce quality)

## Differences from Video Service (Port 8002)

| Feature | Video Service (8002) | Audio Captioner (8003) |
|---------|---------------------|------------------------|
| Input | Video (visual + audio) + prompts | Audio only, no prompts |
| Output | Text based on prompt | Auto-generated caption |
| Model | Qwen3-Omni-30B-A3B-Thinking | Qwen3-Omni-30B-A3B-Captioner |
| Use Case | Video Q&A, analysis | Audio captioning |
| Optimal Length | ~60s videos | ~30s audio |

## Directory Structure

```
qwen3-captioner-service/
├── start_service.sh      # Start the vLLM server
├── stop_service.sh       # Stop the service
├── config.env           # Configuration variables
├── config.env.example   # Configuration template
├── test_client.py       # Test client script
├── logs/               # Service logs
└── README.md           # This file
```

## Dependencies

Installed in virtual environment at `/home/naresh/venvs/qwen3-captioner-service/`:

- vLLM (Qwen3-Omni branch)
- PyTorch 2.7.0
- Transformers (from source)
- accelerate
- qwen-omni-utils
- Other dependencies

## Support

For issues related to:
- **Model**: See [Qwen3-Omni GitHub](https://github.com/QwenLM/Qwen3-Omni) or [Hugging Face Model Card](https://huggingface.co/Qwen/Qwen3-Omni-30B-A3B-Captioner)
- **vLLM**: See [vLLM Documentation](https://docs.vllm.ai/)
- **Service Configuration**: Check logs and GPU status

## License

The Qwen3-Omni-30B-A3B-Captioner model is licensed under Apache 2.0. See the model repository for details.

---

**Note**: This is a production deployment for audio captioning. Monitor GPU usage and service logs for optimal performance. The service runs on port 8003 and can operate simultaneously with the video service on port 8002.








