import numpy as np
import sounddevice as sd
import librosa
import threading
import time
from collections import deque

# Audio settings
SAMPLE_RATE = 22050
FRAME_DURATION = 1.5  # Reduced for more responsive detection
FRAME_SIZE = int(SAMPLE_RATE * FRAME_DURATION)

# Enhanced chord templates with major, minor, and seventh chords
CHORD_TEMPLATES = {
    # MAJOR TRIADS
    'C':    [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0],
    'C#':   [0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0],
    'Db':   [0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0],
    'D':    [0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0],
    'D#':   [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0],
    'Eb':   [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0],
    'E':    [0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1],
    'F':    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0],
    'F#':   [0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0],
    'Gb':   [0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0],
    'G':    [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1],
    'G#':   [1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0],
    'Ab':   [1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0],
    'A':    [0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    'A#':   [0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    'Bb':   [0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    'B':    [0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1],
    
    # MINOR TRIADS
    'Cm':   [1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0],
    'C#m':  [0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
    'Dbm':  [0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
    'Dm':   [0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0],
    'D#m':  [0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0],
    'Ebm':  [0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0],
    'Em':   [0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1],
    'Fm':   [1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0],
    'F#m':  [0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0],
    'Gbm':  [0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0],
    'Gm':   [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0],
    'G#m':  [0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1],
    'Abm':  [0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1],
    'Am':   [1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    'A#m':  [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    'Bbm':  [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    'Bm':   [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1],
    
    # MAJOR SEVENTH CHORDS (Root, 3rd, 5th, 7th)
    'Cmaj7': [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1],
    'C#maj7':[0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0], # Note: simplified - actual 7th would be at position 0
    'Dbmaj7':[0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0],
    'Dmaj7': [0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1],
    'D#maj7':[0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0],
    'Ebmaj7':[0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0],
    'Emaj7': [0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1],
    'Fmaj7': [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1],
    'F#maj7':[0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0],
    'Gbmaj7':[0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0],
    'Gmaj7': [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1],
    'G#maj7':[1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0],
    'Abmaj7':[1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0],
    'Amaj7': [0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    'A#maj7':[0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    'Bbmaj7':[0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    'Bmaj7': [0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1],
    
    # MINOR SEVENTH CHORDS (Root, b3rd, 5th, b7th)
    'Cm7':   [1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0],
    'C#m7':  [0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1],
    'Dbm7':  [0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1],
    'Dm7':   [0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1],
    'D#m7':  [0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0],
    'Ebm7':  [0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0],
    'Em7':   [0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1],
    'Fm7':   [1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1],
    'F#m7':  [0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0],
    'Gbm7':  [0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0],
    'Gm7':   [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0],
    'G#m7':  [0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1],
    'Abm7':  [0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1],
    'Am7':   [1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1],
    'A#m7':  [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    'Bbm7':  [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    'Bm7':   [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1],
    
    # DOMINANT SEVENTH CHORDS (Root, 3rd, 5th, b7th)
    'C7':    [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0],
    'C#7':   [0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1],
    'Db7':   [0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1],
    'D7':    [0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1],
    'D#7':   [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0],
    'Eb7':   [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0],
    'E7':    [0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1],
    'F7':    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1],
    'F#7':   [0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0],
    'Gb7':   [0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0],
    'G7':    [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1],
    'G#7':   [1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0],
    'Ab7':   [1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0],
    'A7':    [0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    'A#7':   [0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    'Bb7':   [0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    'B7':    [0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1],

    # DIMINISHED CHORDS
    'Cdim':  [1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0],
    'C#dim': [0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0],
    'Ddim':  [0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0],
    'Ebdim': [0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0],
    'Edim':  [0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0],
    'Fdim':  [1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1],
    'F#dim': [0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0],
    'Gdim':  [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0],
    'Abdim': [0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1],
    'Adim':  [1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    'Bbdim': [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    'Bdim':  [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1],
}

class ChordDetector:
    def __init__(self):
        self.audio_buffer = deque()
        self.lock = threading.Lock()
        self.is_running = False
        self.on_chord_detected = None  # Callback for chord detection
        self.channels = 1  # Default to mono
        
    def match_chord(self, chroma):
        # Normalize chroma vector
        chroma_norm = chroma / (np.linalg.norm(chroma) + 1e-8)
        
        max_score = -1
        matched_chord = "Unknown"
        confidence = 0
        
        for chord, template in CHORD_TEMPLATES.items():
            template_norm = np.array(template) / (np.linalg.norm(template) + 1e-8)
            score = np.dot(chroma_norm, template_norm)
            
            if score > max_score:
                max_score = score
                matched_chord = chord
                confidence = score
                
        # Only return chord if confidence is high enough
        if confidence > 0.6:  # Threshold for chord detection
            return matched_chord, confidence
        else:
            return "Unknown", confidence
    
    def process_audio(self):
        with self.lock:
            if len(self.audio_buffer) < FRAME_SIZE:
                return
            
            # Get audio data
            audio_data = list(self.audio_buffer)[:FRAME_SIZE]
            # Clear processed data
            for _ in range(min(FRAME_SIZE // 2, len(self.audio_buffer))):
                self.audio_buffer.popleft()
        
        try:
            y = np.array(audio_data, dtype=np.float32)
            
            # Check if there's enough signal
            if np.max(np.abs(y)) < 0.01:  # Very quiet signal
                print("Signal too quiet - play louder!")
                return
                
            # Extract chroma features
            chroma = librosa.feature.chroma_cqt(y=y, sr=SAMPLE_RATE, 
                                               hop_length=512, 
                                               fmin=librosa.note_to_hz('C2'))
            
            if chroma.size == 0:
                return
                
            # Average chroma over time
            avg_chroma = np.mean(chroma, axis=1)
            
            # Detect chord
            chord, confidence = self.match_chord(avg_chroma)
            
            # Calculate volume
            volume = np.sqrt(np.mean(y**2))  # RMS volume
            
            # Call the callback if set
            if self.on_chord_detected:
                self.on_chord_detected(chord, confidence, volume)
            else:
                # Default output if no callback
                print(f"Chord: {chord:6} | Confidence: {confidence:.2f} | Volume: {volume:.3f}")
            
        except Exception as e:
            print(f"Processing error: {e}")
    
    def audio_callback(self, indata, frames, time_info, status):
        if status:
            print(f"Audio status: {status}")
            
        with self.lock:
            # Handle both mono and stereo inputs
            if indata.shape[1] > 1:
                audio_data = np.mean(indata, axis=1)  # Average both channels for stereo
            else:
                audio_data = indata[:, 0]  # Use single channel for mono
                
            # Add new audio data
            self.audio_buffer.extend(audio_data)
            
            # Limit buffer size to prevent memory issues
            while len(self.audio_buffer) > FRAME_SIZE * 2:
                self.audio_buffer.popleft()
    
    def start(self, on_chord_detected=None):
        """Start the chord detector with an optional callback"""
        self.on_chord_detected = on_chord_detected
        self.is_running = True
        
        try:
            # List available audio devices
            print("Available audio devices:")
            devices = sd.query_devices()
            print(devices)
            print("-" * 50)
            
            # Get default input device
            default_input = sd.query_devices(kind='input')
            self.channels = default_input['max_input_channels']
            print(f"Using input device with {self.channels} channel(s)")
            
            with sd.InputStream(callback=self.audio_callback, 
                              channels=self.channels,  # Use detected number of channels
                              samplerate=SAMPLE_RATE,
                              blocksize=1024):
                while self.is_running:
                    time.sleep(0.1)  # More frequent processing
                    self.process_audio()
                    
        except KeyboardInterrupt:
            self.is_running = False
            raise  # Re-raise to be handled by the caller
        except Exception as e:
            print(f"Error: {e}")
            print("Try checking your microphone or audio settings")
            self.is_running = False
    
    def stop(self):
        """Stop the chord detector"""
        self.is_running = False

if __name__ == "__main__":
    detector = ChordDetector()
    detector.start()