#!/usr/bin/env python3

import asyncio
import websockets
import json

async def debug_websocket():
    uri = "ws://localhost:8000/ws"
    
    try:
        print(f"🔌 Connecting to {uri}...")
        async with websockets.connect(uri) as websocket:
            print("✅ Connected successfully!")
            
            # Test 1: Start session
            print("\n🧪 Starting session...")
            start_message = {"type": "start_session", "confidence_threshold": 0.5}
            await websocket.send(json.dumps(start_message))
            response = await websocket.recv()
            print(f"📨 Start response: {response}")
            
            # Test 2: Send simple audio data
            print("\n🧪 Sending simple audio data...")
            # Create a simple audio pattern that should be easy to detect
            simple_audio = [1000, -1000] * 8000  # Simple square wave, 16000 samples
            
            audio_message = {
                "type": "audio_data", 
                "data": simple_audio
            }
            await websocket.send(json.dumps(audio_message))
            print("📤 Sent simple audio data")
            
            # Wait for any responses
            print("⏳ Waiting for responses...")
            try:
                for i in range(5):
                    response = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                    print(f"📨 Response {i+1}: {response}")
            except asyncio.TimeoutError:
                print("⏰ No more responses")
            
            # Test 3: Stop session
            print("\n🧪 Stopping session...")
            stop_message = {"type": "stop_session"}
            await websocket.send(json.dumps(stop_message))
            
            # Wait for final responses
            try:
                for i in range(3):
                    response = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                    print(f"📨 Stop response {i+1}: {response}")
            except asyncio.TimeoutError:
                print("⏰ Session ended")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    print("🔍 WebSocket Debug Test")
    print("=" * 30)
    asyncio.run(debug_websocket())
