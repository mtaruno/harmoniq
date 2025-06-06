import asyncio
import json
import time
from datetime import datetime
from typing import Dict, List, Optional
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import threading
from live_chord_progression import ProgressionDetector

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

class HarmoniqSession:
    def __init__(self, websocket: WebSocket):
        self.websocket = websocket
        self.detector = None
        self.is_active = False
        self.session_id = None
        self.start_time = None
        self.chord_history = []
        self.confidence_threshold = 0.7
        
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
        
        # Create detector with callback
        self.detector = ProgressionDetector()
        
        # Override the on_chord_detected method to send WebSocket messages
        original_callback = self.detector.on_chord_detected
        
        def websocket_callback(chord, confidence, volume):
            # Call original callback for internal processing
            original_callback(chord, confidence, volume)
            
            # Send WebSocket message
            asyncio.create_task(self._send_chord_detected(chord, confidence, volume))
            
            # Check for key detection
            if self.detector.current_key:
                asyncio.create_task(self._send_key_detected(
                    self.detector.current_key, 
                    self.detector.key_confidence
                ))
        
        self.detector.on_chord_detected = websocket_callback
        
        # Start detector in background thread
        self.detector_thread = threading.Thread(target=self._run_detector)
        self.detector_thread.daemon = True
        self.is_active = True
        self.detector_thread.start()
        
        await manager.send_personal_message({
            "type": "session_started",
            "session_id": self.session_id,
            "confidence_threshold": confidence_threshold
        }, self.websocket)
        
    def _run_detector(self):
        """Run the chord detector in a separate thread"""
        try:
            self.detector.run()
        except Exception as e:
            print(f"Detector error: {e}")
            asyncio.create_task(manager.send_personal_message({
                "type": "error",
                "message": f"Detector error: {str(e)}"
            }, self.websocket))
            
    async def _send_chord_detected(self, chord, confidence, volume):
        """Send chord detection message via WebSocket"""
        if not self.is_active:
            return
            
        # Calculate timestamp relative to session start
        timestamp_ms = int((datetime.now() - self.start_time).total_seconds() * 1000)
        
        # Get Roman numeral if key is detected
        roman = None
        if self.detector and self.detector.current_key:
            roman = self.detector.chord_to_roman(chord, self.detector.current_key)
            
        # Store in history
        chord_data = {
            "chord": chord,
            "confidence": confidence,
            "volume": volume,
            "timestamp_ms": timestamp_ms,
            "roman": roman
        }
        self.chord_history.append(chord_data)
        
        # Send WebSocket message
        await manager.send_personal_message({
            "type": "chord_detected",
            **chord_data
        }, self.websocket)
        
    async def _send_key_detected(self, key, confidence):
        """Send key detection message via WebSocket"""
        await manager.send_personal_message({
            "type": "key_detected",
            "key": key,
            "confidence": confidence
        }, self.websocket)
        
    async def stop_session(self):
        """Stop the current session"""
        if not self.is_active:
            await manager.send_personal_message({
                "type": "error",
                "message": "No active session"
            }, self.websocket)
            return
            
        self.is_active = False
        
        if self.detector:
            self.detector.stop()
            
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
                
        # Get Roman numeral progression
        if self.detector and self.detector.current_key:
            analysis["roman_progression"] = [
                entry.get("roman", entry["chord"]) 
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
            "detected_key": self.detector.current_key if self.detector else None,
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
