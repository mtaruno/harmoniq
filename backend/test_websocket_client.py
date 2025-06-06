#!/usr/bin/env python3

import asyncio
import websockets
import json
import time

async def test_websocket_connection():
    uri = "ws://localhost:8000/ws"
    
    try:
        print(f"Connecting to {uri}...")
        async with websockets.connect(uri) as websocket:
            print("✅ Connected successfully!")
            
            # Test 1: Start session
            print("\n🧪 Test 1: Starting session...")
            start_message = {
                "type": "start_session",
                "confidence_threshold": 0.7
            }
            await websocket.send(json.dumps(start_message))
            
            # Wait for response
            response = await websocket.recv()
            print(f"📨 Response: {response}")
            
            # Test 2: Send some dummy audio data
            print("\n🧪 Test 2: Sending dummy audio data...")
            dummy_audio = [0] * 1024  # 1024 zeros as dummy audio
            audio_message = {
                "type": "audio_data",
                "data": dummy_audio
            }
            await websocket.send(json.dumps(audio_message))
            
            # Wait a bit to see if we get any chord detections
            print("⏳ Waiting for potential chord detections...")
            try:
                for i in range(3):  # Wait for up to 3 messages
                    response = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                    print(f"📨 Message {i+1}: {response}")
            except asyncio.TimeoutError:
                print("⏰ No more messages received (timeout)")
            
            # Test 3: Stop session
            print("\n🧪 Test 3: Stopping session...")
            stop_message = {"type": "stop_session"}
            await websocket.send(json.dumps(stop_message))
            
            # Wait for response
            response = await websocket.recv()
            print(f"📨 Response: {response}")
            
            print("\n✅ All tests completed successfully!")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    print("🔌 WebSocket Client Test")
    print("=" * 40)
    asyncio.run(test_websocket_connection())
