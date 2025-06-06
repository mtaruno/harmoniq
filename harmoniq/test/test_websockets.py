import asyncio
import websockets
import json
import numpy as np

async def test_websocket():
    uri = "ws://localhost:8000/ws"
    print(f"🔌 Connecting to {uri}...")

    async with websockets.connect(uri) as websocket:
        print("✅ Connected successfully!")

        # Test 1: Start session
        print("\n🧪 Test 1: Starting session...")
        start_message = {
            "type": "start_session",
            "confidence_threshold": 0.7
        }
        await websocket.send(json.dumps(start_message))
        response = await websocket.recv()
        print(f"📨 Start session response: {response}")

        # Test 2: Send realistic audio data (sine wave for C major chord)
        print("\n🧪 Test 2: Sending audio data (C major chord simulation)...")

        # Generate a more realistic C major chord with harmonics
        sample_rate = 16000
        duration = 2.0  # 2 seconds for better detection
        t = np.linspace(0, duration, int(sample_rate * duration))

        # C major chord frequencies with harmonics
        c_freq = 261.63  # C4
        e_freq = 329.63  # E4
        g_freq = 392.00  # G4

        # Generate chord with harmonics and envelope
        envelope = np.exp(-t * 0.5)  # Decay envelope
        chord_signal = (
            np.sin(2 * np.pi * c_freq * t) * envelope +
            np.sin(2 * np.pi * e_freq * t) * envelope +
            np.sin(2 * np.pi * g_freq * t) * envelope +
            # Add some harmonics
            0.3 * np.sin(2 * np.pi * c_freq * 2 * t) * envelope +
            0.3 * np.sin(2 * np.pi * e_freq * 2 * t) * envelope +
            0.3 * np.sin(2 * np.pi * g_freq * 2 * t) * envelope
        ) / 4

        # Add some noise for realism
        noise = np.random.normal(0, 0.01, len(chord_signal))
        chord_signal += noise

        # Convert to 16-bit PCM with higher amplitude
        audio_data = (chord_signal * 16383).astype(np.int16)  # Use half range for safety

        # Send audio data in chunks (simulate real streaming)
        chunk_size = 8000  # 0.5 seconds of audio
        for i in range(0, len(audio_data), chunk_size):
            chunk = audio_data[i:i + chunk_size]
            audio_message = {
                "type": "audio_data",
                "data": chunk.tolist()
            }
            await websocket.send(json.dumps(audio_message))
            print(f"📤 Sent audio chunk {i//chunk_size + 1}/{(len(audio_data) + chunk_size - 1)//chunk_size}")
            await asyncio.sleep(0.5)  # Wait 0.5 seconds between chunks

        # Wait for chord detection
        print("⏳ Waiting for chord detection...")
        try:
            for i in range(5):  # Wait for up to 5 messages
                response = await asyncio.wait_for(websocket.recv(), timeout=3.0)
                print(f"📨 Detection {i+1}: {response}")
        except asyncio.TimeoutError:
            print("⏰ No chord detections received")

        # Test 3: Stop session
        print("\n🧪 Test 3: Stopping session...")
        stop_message = {"type": "stop_session"}
        await websocket.send(json.dumps(stop_message))

        # Wait for session end responses
        try:
            for i in range(3):  # Wait for session end messages
                response = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                print(f"📨 Session end {i+1}: {response}")
        except asyncio.TimeoutError:
            print("⏰ Session ended")

        print("\n✅ Test completed!")

if __name__ == "__main__":
    print("🎵 Harmoniq WebSocket Test")
    print("=" * 40)
    asyncio.run(test_websocket())