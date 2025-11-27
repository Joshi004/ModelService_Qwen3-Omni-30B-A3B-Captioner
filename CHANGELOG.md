# Changelog - Qwen3-Omni Audio Captioner Service

## [Updated] - November 14, 2024

### Added - Smart HTTP Server Port Sharing

#### Changes to `start_service.sh`

**New Feature**: Intelligent port 8080 detection and sharing

**Before**:
- Did not start any HTTP server
- Required manual HTTP server or video service running

**After**:
- Checks if port 8080 is already in use
- If in use: Reuses existing HTTP server (no conflict)
- If free: Starts new HTTP server on port 8080
- Serves media files from `/home/naresh/datasets/videos/`

#### Code Changes

Added lines 39-71:
```bash
# Video/Audio server configuration
VIDEO_DIR="/home/naresh/datasets/videos"
VIDEO_PORT=8080

# Check if port 8080 is already in use
if lsof -Pi :$VIDEO_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "HTTP server already running on port 8080 - reusing existing server"
    echo "  Media files accessible at: http://localhost:8080/"
else
    echo "Starting HTTP server for audio/video files..."
    echo "  Directory: $VIDEO_DIR"
    echo "  Port: $VIDEO_PORT"
    
    # Check if directory exists
    if [ ! -d "$VIDEO_DIR" ]; then
        echo "Warning: Directory $VIDEO_DIR does not exist. Creating it..."
        mkdir -p "$VIDEO_DIR"
    fi
    
    # Start Python HTTP server in background
    cd "$VIDEO_DIR"
    python3 -m http.server $VIDEO_PORT > /tmp/video_server.log 2>&1 &
    VIDEO_SERVER_PID=$!
    echo $VIDEO_SERVER_PID > /tmp/video_server.pid
    echo "HTTP server started with PID: $VIDEO_SERVER_PID"
    echo "  Media URLs: http://localhost:8080/<filename>"
    
    # Return to service directory
    cd /home/naresh/qwen3-captioner-service
    
    # Give the HTTP server a moment to start
    sleep 2
fi
```

### Benefits

1. **No Port Conflicts**: Automatically detects and reuses existing HTTP server
2. **Flexible Startup**: Can start audio captioner before or after video service
3. **Shared Resources**: Both services share single HTTP server efficiently
4. **Standalone Operation**: Can run independently without video service
5. **Better UX**: Clear messages about HTTP server status

### Migration Notes

**No action required** - Changes are backward compatible

- Existing setups continue to work
- If video service is running, audio captioner reuses its HTTP server
- If no HTTP server exists, audio captioner starts one
- Startup order no longer matters

### Testing

Test the new behavior:

```bash
# Test 1: Start audio captioner first (new capability)
cd /home/naresh/qwen3-captioner-service
./start_service.sh
# Should start HTTP server on 8080

# Test 2: Start video service second
cd /home/naresh/qwen3-omni-service
./start_service.sh
# Should detect existing HTTP server on 8080

# Test 3: Access media files
curl http://localhost:8080/
# Should list files from /home/naresh/datasets/videos/
```

### Related Changes

- Video service (`qwen3-omni-service`) also updated with same logic
- See `/home/naresh/HTTP_SERVER_SHARING.md` for detailed documentation

---

**Version**: 1.1.0  
**Date**: November 14, 2024  
**Status**: ✅ Production Ready






