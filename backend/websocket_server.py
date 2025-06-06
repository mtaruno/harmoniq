import asyncio
import json
import time
from datetime import datetime
from typing import Dict, List, Optional
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import numpy as np
import librosa
from enhanced_chord_detector import ChordDetector
from live_chord_progression import ProgressionDetector
from collections import deque

app = FastAPI(title="Harmoniq WebSocket Server")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self.session_data: Dict = {}
        
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        
    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
            
    async def send_personal_message(self, message: dict, websocket: WebSocket):
        try:
            await websocket.send_text(json.dumps(message))
        except Exception as e:
            print(f"Error sending message: {e}")
            
    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_text(json.dumps(message))
            except Exception as e:
                print(f"Error broadcasting message: {e}")

manager = ConnectionManager()

class AudioChordDetector:
    """Chord detector that processes audio data from WebSocket clients"""

    def __init__(self, confidence_threshold=0.6):
        self.chord_detector = ChordDetector(confidence_threshold=confidence_threshold)
        self.audio_buffer = deque(maxlen=8192)  # Buffer for incoming audio
        self.sample_rate = 16000  # Flutter app sample rate
        self.on_chord_detected = None

    def process_audio_data(self, audio_bytes):
        """Process incoming audio data and detect chords"""
        try:
            # Convert bytes to numpy array (assuming 16-bit PCM)
            audio_data = np.frombuffer(audio_bytes, dtype=np.int16).astype(np.float32) / 32768.0
            print(f"🎵 Received audio data: {len(audio_data)} samples, buffer size: {len(self.audio_buffer)}")

            # Check audio data range
            if len(audio_data) > 0:
                print(f"📊 Audio range: min={np.min(audio_data):.4f}, max={np.max(audio_data):.4f}, mean={np.mean(audio_data):.4f}")

            # Add to buffer
            self.audio_buffer.extend(audio_data)

            # Process if we have enough data (about 0.5 seconds)
            if len(self.audio_buffer) >= self.sample_rate // 2:
                # Get the last 0.5 seconds of audio
                chunk_size = self.sample_rate // 2
                audio_chunk = np.array(list(self.audio_buffer)[-chunk_size:])

                # Check if there's enough signal
                volume = np.sqrt(np.mean(audio_chunk**2))
                print(f"🔊 Audio volume: {volume:.4f}")

                if volume < 0.01:  # Too quiet
                    print("🔇 Audio too quiet, skipping...")
                    return

                # Resample audio to 22kHz to match ChordDetector expectations
                audio_22k = librosa.resample(audio_chunk, orig_sr=self.sample_rate, target_sr=22050)

                # Extract chroma features using the same method as ChordDetector
                chroma = librosa.feature.chroma_cqt(
                    y=audio_22k,
                    sr=22050,
                    hop_length=512,
                    fmin=librosa.note_to_hz('C2')
                )

                if chroma.size == 0:
                    print("❌ No chroma features extracted")
                    return

                # Average chroma over time
                avg_chroma = np.mean(chroma, axis=1)
                print(f"🎼 Chroma shape: {chroma.shape}, avg_chroma: {avg_chroma}")

                # Detect chord
                chord, confidence = self.chord_detector.match_chord(avg_chroma)
                print(f"🎵 Detected: {chord} (confidence: {confidence:.3f})")

                # Call callback if set
                if self.on_chord_detected and chord != "Unknown":
                    print(f"✅ Calling callback for chord: {chord}")
                    self.on_chord_detected(chord, confidence, volume)
                else:
                    print(f"❌ No callback or unknown chord: {chord}")

        except Exception as e:
            print(f"Error processing audio data: {e}")

    def stop(self):
        """Stop the audio detector"""
        self.audio_buffer.clear()
        self.on_chord_detected = None

class HarmoniqSession:
    def __init__(self, websocket: WebSocket):
        self.websocket = websocket
        self.detector = None
        self.is_active = False
        self.session_id = None
        self.start_time = None
        self.chord_history = []
        self.confidence_threshold = 0.7
        self.event_loop = None
        
    async def start_session(self, confidence_threshold: float = 0.7):
        """Start a new chord detection session"""
        if self.is_active:
            await manager.send_personal_message({
                "type": "error",
                "message": "Session already active"
            }, self.websocket)
            return
            
        self.confidence_threshold = confidence_threshold
        self.start_time = datetime.now()
        self.chord_history = []
        self.session_id = int(time.time())

        # Store the current event loop for use in callbacks
        self.event_loop = asyncio.get_event_loop()
        
        # Create full progression detector for advanced analysis
        self.progression_detector = ProgressionDetector()
        # Override the confidence threshold for mobile audio
        self.progression_detector.mobile_confidence_threshold = 0.55
        # Use lower confidence threshold for WebSocket (mobile audio is often noisier)
        self.audio_detector = AudioChordDetector(confidence_threshold=max(0.5, confidence_threshold * 0.8))

        # Set up callback for chord detection
        def websocket_callback(chord, confidence, volume):
            # Custom progression tracking with lower confidence threshold for mobile audio
            self._track_chord_progression(chord, confidence, volume)


        self.audio_detector.on_chord_detected = websocket_callback
        self.is_active = True

        # Initialize progression tracking variables
        self.last_chord = None
        self.chord_start_time = None
        
        await manager.send_personal_message({
            "type": "session_started",
            "session_id": self.session_id,
            "confidence_threshold": confidence_threshold
        }, self.websocket)

    def _track_chord_progression(self, chord, confidence, volume):
        """Custom chord progression tracking with lower confidence threshold"""
        from datetime import datetime
        current_time = datetime.now()

        # Track chord changes for progression (lower confidence threshold for mobile)
        if (chord != self.last_chord and
            chord != "Unknown" and
            confidence > 0.55):  # Lower threshold for mobile audio

            if self.last_chord and self.chord_start_time:
                # Calculate duration of previous chord
                duration = (current_time - self.chord_start_time).total_seconds()
                # Update the last entry with duration
                if self.progression_detector.chord_history:
                    self.progression_detector.chord_history[-1]['duration'] = duration

            # Add new chord to progression detector's history
            self.progression_detector.chord_history.append({
                'chord': chord,
                'time': current_time,
                'confidence': confidence,
                'duration': 0
            })

            self.last_chord = chord
            self.chord_start_time = current_time

            print(f"🎼 Added to progression: {chord} (confidence: {confidence:.2f})")

            # Update key detection periodically
            if len(self.progression_detector.chord_history) % 3 == 0:
                recent_chords = [entry['chord'] for entry in self.progression_detector.chord_history[-8:]]
                detected_key, key_confidence = self.progression_detector.detect_key(recent_chords)
                if detected_key and key_confidence > 0.5:
                    if self.progression_detector.current_key != detected_key:
                        self.progression_detector.current_key = detected_key
                        self.progression_detector.key_confidence = key_confidence
                        print(f"🗝️  Key detected: {detected_key}")

        # Always send to WebSocket regardless of progression tracking
        try:
            if self.event_loop and self.event_loop.is_running():
                # Send chord detection
                print(f"📤 Sending chord to WebSocket: {chord} (confidence: {confidence:.2f})")
                asyncio.run_coroutine_threadsafe(
                    self._send_chord_detected(chord, confidence, volume), self.event_loop
                )

                # Send key detection if available
                if self.progression_detector.current_key:
                    print(f"📤 Sending key to WebSocket: {self.progression_detector.current_key}")
                    asyncio.run_coroutine_threadsafe(
                        self._send_key_detected(
                            self.progression_detector.current_key,
                            self.progression_detector.key_confidence
                        ), self.event_loop
                    )
            else:
                print(f"❌ Event loop not available, chord detected: {chord} (confidence: {confidence:.2f})")
                print(f"   Event loop: {self.event_loop}")
                print(f"   Is running: {self.event_loop.is_running() if self.event_loop else 'N/A'}")
        except Exception as e:
            print(f"❌ Error in websocket callback: {e}")
            print(f"   Chord detected: {chord} (confidence: {confidence:.2f})")
            import traceback
            traceback.print_exc()
        
    async def process_audio_data(self, audio_data):
        """Process incoming audio data from client"""
        if not self.is_active:
            return

        try:
            # Process the audio data
            self.audio_detector.process_audio_data(audio_data)
        except Exception as e:
            print(f"Error processing audio data: {e}")
            await manager.send_personal_message({
                "type": "error",
                "message": f"Audio processing error: {str(e)}"
            }, self.websocket)
            
    async def _send_chord_detected(self, chord, confidence, volume):
        """Send chord detection message via WebSocket"""
        if not self.is_active:
            return
            
        # Calculate timestamp relative to session start
        timestamp_ms = int((datetime.now() - self.start_time).total_seconds() * 1000)
        
        # Get Roman numeral if key is detected
        roman = None
        if self.progression_detector.current_key:
            roman = self.progression_detector.chord_to_roman(chord, self.progression_detector.current_key)
            
        # Store in history (convert numpy types to Python types for JSON serialization)
        chord_data = {
            "chord": str(chord),
            "confidence": float(confidence),
            "volume": float(volume),
            "timestamp_ms": int(timestamp_ms),
            "roman": str(roman) if roman else None
        }
        self.chord_history.append(chord_data)
        
        # Send WebSocket message
        message = {
            "type": "chord_detected",
            **chord_data
        }
        print(f"📤 Sending WebSocket message: {message}")
        await manager.send_personal_message(message, self.websocket)
        
    async def _send_key_detected(self, key, confidence):
        """Send key detection message via WebSocket"""
        message = {
            "type": "key_detected",
            "key": key,
            "confidence": confidence,
            "diatonic_chords": self.progression_detector.get_diatonic_chords(key) if self.progression_detector else []
        }
        print(f"📤 Sending key detection: {message}")
        await manager.send_personal_message(message, self.websocket)
        
    async def stop_session(self):
        """Stop the current session"""
        if not self.is_active:
            await manager.send_personal_message({
                "type": "error",
                "message": "No active session"
            }, self.websocket)
            return
            
        self.is_active = False

        if self.audio_detector:
            self.audio_detector.stop()
        if self.progression_detector:
            self.progression_detector.stop()
            
        # Calculate session summary
        end_time = datetime.now()
        duration = (end_time - self.start_time).total_seconds()
        
        # Get unique chords
        unique_chords = set(entry["chord"] for entry in self.chord_history if entry["chord"] != "Unknown")
        
        # Create analysis data
        analysis = {
            "chord_frequency": {},
            "patterns": [],
            "roman_progression": []
        }
        
        # Calculate chord frequency
        for entry in self.chord_history:
            chord = entry["chord"]
            if chord != "Unknown":
                analysis["chord_frequency"][chord] = analysis["chord_frequency"].get(chord, 0) + 1
                
        # Roman numeral progression
        if self.progression_detector and self.progression_detector.current_key:
            analysis["roman_progression"] = [
                entry.get("roman", entry["chord"])
                for entry in self.chord_history
                if entry["chord"] != "Unknown"
            ]
        else:
            analysis["roman_progression"] = [
                entry["chord"]
                for entry in self.chord_history
                if entry["chord"] != "Unknown"
            ]
        
        # Send session ended message
        await manager.send_personal_message({
            "type": "session_ended",
            "session_id": self.session_id
        }, self.websocket)
        
        # Send session summary
        await manager.send_personal_message({
            "type": "session_summary",
            "session_id": self.session_id,
            "duration": duration,
            "chord_count": len(self.chord_history),
            "unique_chords": len(unique_chords),
            "detected_key": self.progression_detector.current_key if self.progression_detector else None,
            "chord_history": self.chord_history,
            "analysis": analysis
        }, self.websocket)
        
    async def update_confidence_threshold(self, threshold: float):
        """Update the confidence threshold during session"""
        self.confidence_threshold = threshold
        
        if self.detector:
            # Update the detector's threshold if possible
            # Note: The current detector doesn't support dynamic threshold updates
            # This would require modifying the detector class
            pass
            
        await manager.send_personal_message({
            "type": "threshold_updated",
            "confidence_threshold": threshold
        }, self.websocket)

# Store active sessions
active_sessions: Dict[WebSocket, HarmoniqSession] = {}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    session = HarmoniqSession(websocket)
    active_sessions[websocket] = session
    
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            message_type = message.get("type")
            
            if message_type == "start_session":
                confidence_threshold = message.get("confidence_threshold", 0.7)
                await session.start_session(confidence_threshold)
                
            elif message_type == "stop_session":
                await session.stop_session()
                
            elif message_type == "update_threshold":
                threshold = message.get("confidence_threshold", 0.7)
                await session.update_confidence_threshold(threshold)

            elif message_type == "audio_data":
                # Handle incoming audio data from client
                audio_data = message.get("data")
                if audio_data and session.is_active:
                    # Convert list of integers back to bytes
                    audio_bytes = bytes(audio_data)
                    await session.process_audio_data(audio_bytes)

            else:
                await manager.send_personal_message({
                    "type": "error",
                    "message": f"Unknown message type: {message_type}"
                }, websocket)
                
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        if websocket in active_sessions:
            session = active_sessions[websocket]
            if session.is_active:
                await session.stop_session()
            del active_sessions[websocket]
    except Exception as e:
        print(f"WebSocket error: {e}")
        manager.disconnect(websocket)
        if websocket in active_sessions:
            del active_sessions[websocket]

@app.get("/")
async def root():
    return {"message": "Harmoniq WebSocket Server is running"}

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "active_connections": len(manager.active_connections),
        "active_sessions": len(active_sessions)
    }

if __name__ == "__main__":
    print("🎼 Starting Harmoniq WebSocket Server...")
    print("🔗 WebSocket endpoint: ws://localhost:8000/ws")
    print("🌐 Health check: http://localhost:8000/health")
    
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=8000,
        log_level="info"
    )
