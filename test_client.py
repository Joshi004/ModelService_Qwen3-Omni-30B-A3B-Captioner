#!/usr/bin/env python3
"""
Qwen3-Omni Audio Captioner Service Test Client

This script tests the vLLM audio captioning service with audio URLs.
The Captioner model automatically generates detailed captions for audio inputs
without requiring any text prompts.
"""

import json
import requests
import sys
from typing import Optional


def test_audio_caption(
    audio_url: str,
    base_url: str = "http://localhost:8003",
    temperature: float = 0.6,
    top_p: float = 0.95,
    top_k: int = 20,
    max_tokens: int = 16384,
):
    """
    Test the Qwen3-Omni Audio Captioner service with an audio URL.
    
    Note: The Captioner model does NOT accept text prompts. It automatically
    generates detailed captions for the audio input.
    
    Args:
        audio_url: URL to the audio file (mp3, wav, etc.)
        base_url: Base URL of the vLLM service
        temperature: Sampling temperature
        top_p: Top-p sampling parameter
        top_k: Top-k sampling parameter
        max_tokens: Maximum tokens to generate
    
    Returns:
        dict: Response from the service
    """
    
    # Construct the API endpoint
    api_url = f"{base_url}/v1/chat/completions"
    
    # Prepare the request payload - audio only, no text prompt
    payload = {
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "audio_url", "audio_url": {"url": audio_url}}
                ]
            }
        ],
        "temperature": temperature,
        "top_p": top_p,
        "top_k": top_k,
        "max_tokens": max_tokens,
    }
    
    print(f"🔄 Sending request to {api_url}")
    print(f"🎵 Audio URL: {audio_url}")
    print(f"ℹ️  Note: Captioner model auto-generates captions (no prompt needed)")
    print("-" * 80)
    
    try:
        # Send POST request
        response = requests.post(
            api_url,
            headers={"Content-Type": "application/json"},
            json=payload,
            timeout=300  # 5 minute timeout
        )
        
        response.raise_for_status()
        
        # Parse response
        result = response.json()
        
        # Extract generated caption
        if "choices" in result and len(result["choices"]) > 0:
            caption = result["choices"][0]["message"]["content"]
            print("✅ Caption generated!")
            print("-" * 80)
            print("📝 Audio Caption:")
            print(caption)
            print("-" * 80)
            
            # Print usage stats if available
            if "usage" in result:
                print(f"📊 Usage Stats:")
                print(f"   Prompt tokens: {result['usage'].get('prompt_tokens', 'N/A')}")
                print(f"   Completion tokens: {result['usage'].get('completion_tokens', 'N/A')}")
                print(f"   Total tokens: {result['usage'].get('total_tokens', 'N/A')}")
            
            return {
                "success": True,
                "caption": caption,
                "full_response": result
            }
        else:
            print("❌ Unexpected response format")
            print(json.dumps(result, indent=2))
            return {"success": False, "error": "Unexpected response format"}
            
    except requests.exceptions.Timeout:
        error_msg = "Request timed out after 5 minutes"
        print(f"❌ {error_msg}")
        return {"success": False, "error": error_msg}
    
    except requests.exceptions.ConnectionError:
        error_msg = f"Failed to connect to {base_url}. Is the service running?"
        print(f"❌ {error_msg}")
        return {"success": False, "error": error_msg}
    
    except requests.exceptions.HTTPError as e:
        error_msg = f"HTTP error: {e.response.status_code} - {e.response.text}"
        print(f"❌ {error_msg}")
        return {"success": False, "error": error_msg}
    
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        print(f"❌ {error_msg}")
        return {"success": False, "error": error_msg}


def main():
    """Main function to run example tests"""
    
    print("=" * 80)
    print("Qwen3-Omni Audio Captioner Service Test Client")
    print("=" * 80)
    print()
    
    # Example: Test with a sample audio URL from Qwen3-Omni cookbook
    example_audio_url = "https://qianwen-res.oss-cn-beijing.aliyuncs.com/Qwen3-Omni/cookbook/caption2.mp3"
    
    print("📝 Example Test:")
    print(f"   Audio: {example_audio_url}")
    print(f"   Mode: Auto-caption (no prompt needed)")
    print()
    
    # Check if custom audio URL provided
    if len(sys.argv) >= 2:
        audio_url = sys.argv[1]
        print("Using custom audio URL from command line argument")
    else:
        audio_url = example_audio_url
        print("Using example audio (no command line args provided)")
        print("Usage: python test_client.py <audio_url>")
    
    print()
    print("⚠️  Note: Optimal audio length is ≤ 30 seconds for best caption quality")
    print()
    
    # Run the test
    result = test_audio_caption(audio_url)
    
    # Exit with appropriate code
    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()








