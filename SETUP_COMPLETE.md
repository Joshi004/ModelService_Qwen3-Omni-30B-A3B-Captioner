# Qwen3-Omni Audio Captioner Service - Setup Complete ✅

## Summary

The Qwen3-Omni Audio Captioner Service has been successfully set up and is ready to use!

## What Was Created

### 1. Service Directory Structure
```
/home/naresh/qwen3-captioner-service/
├── start_service.sh         # Service startup script
├── stop_service.sh          # Service shutdown script
├── config.env               # Active configuration
├── config.env.example       # Configuration template
├── test_client.py           # Python test client
├── README.md                # Comprehensive documentation
├── logs/                    # Service logs directory
└── SETUP_COMPLETE.md        # This file
```

### 2. Model Downloaded
- **Location**: `/home/naresh/models/qwen3-omni-30b-captioner/`
- **Size**: ~60GB (16 safetensor files)
- **Model**: Qwen3-Omni-30B-A3B-Captioner
- **Status**: ✅ All files downloaded successfully

### 3. Virtual Environment
- **Location**: `/home/naresh/venvs/qwen3-captioner-service/`
- **Python**: 3.10
- **Key Dependencies Installed**:
  - ✅ vLLM 0.9.3.dev6+gca66cbff0 (Qwen3-Omni branch)
  - ✅ Transformers 4.57.1
  - ✅ PyTorch 2.7.0+cu126
  - ✅ qwen-omni-utils 0.0.8
  - ✅ Accelerate 1.11.0
  - ✅ All CUDA libraries

### 4. Service Configuration
- **Port**: 8003
- **GPUs**: 2x H100 (tensor parallelism enabled)
- **Max Model Length**: 32,768 tokens (~30s audio)
- **GPU Memory**: 95% utilization
- **Max Concurrent Sequences**: 8

## Quick Start Guide

### Start the Service

```bash
cd /home/naresh/qwen3-captioner-service
./start_service.sh
```

The service will start on port 8003 and be ready to accept requests.

### Test the Service

```bash
# Test with built-in example audio
python test_client.py

# Or test with your own audio URL
python test_client.py "https://example.com/audio.mp3"

# Or use curl
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

### Stop the Service

```bash
./stop_service.sh
```

## Important Notes

### About This Model
- **Input**: Audio URLs only (no text prompts)
- **Output**: Detailed text captions
- **Optimal Audio Length**: ≤ 30 seconds for best results
- **No Prompts Needed**: The model automatically generates captions

### Differences from Video Service (Port 8002)
| Feature | Video Service (8002) | Audio Captioner (8003) |
|---------|---------------------|------------------------|
| Input | Video + audio + prompts | Audio only, no prompts |
| Output | Custom text responses | Auto-generated captions |
| Model | Qwen3-Omni-30B-A3B-Thinking | Qwen3-Omni-30B-A3B-Captioner |

### Running Both Services
Both services can run simultaneously:
- Video Service: Port 8002
- Audio Captioner: Port 8003
- They use the same GPUs with tensor parallelism

## SSH Tunneling (for Remote Access)

If you need to access from your local machine:

```bash
# From your local machine
ssh -L 8003:localhost:8003 user@remote-server

# Then access at http://localhost:8003 from your local browser/tools
```

## Service Management

### Check Status
```bash
# Check if running
curl http://localhost:8003/health

# Check processes
ps aux | grep vllm | grep 8003

# Monitor GPUs
nvidia-smi
```

### View Logs
```bash
tail -f /home/naresh/qwen3-captioner-service/logs/service.log
```

## Troubleshooting

If you encounter issues:

1. **Service won't start**: Check that port 8003 is available
2. **Out of memory**: Reduce GPU_MEMORY_UTIL in start_service.sh
3. **Connection refused**: Ensure service is running and SSH tunnel is active (if remote)
4. **Poor captions**: Keep audio clips ≤ 30 seconds for best quality

See `README.md` for detailed troubleshooting guide.

## Next Steps

1. Start the service: `./start_service.sh`
2. Test with the example: `python test_client.py`
3. Try with your own audio files
4. Read `README.md` for advanced usage and API details

## Support

- Model documentation: https://huggingface.co/Qwen/Qwen3-Omni-30B-A3B-Captioner
- vLLM documentation: https://docs.vllm.ai/
- Service files: `/home/naresh/qwen3-captioner-service/`

---

**Setup completed on**: November 14, 2024  
**Service ready**: ✅ Yes  
**Port**: 8003  
**Status**: Ready to start








