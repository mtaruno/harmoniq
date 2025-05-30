import numpy as np
import sounddevice as sd
import librosa
import threading
import time
from collections import deque, Counter
from datetime import datetime, timedelta

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
    'C#maj7':[0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0],
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

# Key signatures with diminished chords
MAJOR_KEYS = {
    'C': ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim'],
    'G': ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'F#dim'],
    'D': ['D', 'Em', 'F#m', 'G', 'A', 'Bm', 'C#dim'],
    'A': ['A', 'Bm', 'C#m', 'D', 'E', 'F#m', 'G#dim'],
    'E': ['E', 'F#m', 'G#m', 'A', 'B', 'C#m', 'D#dim'],
    'F': ['F', 'Gm', 'Am', 'Bb', 'C', 'Dm', 'Edim'],
    'Bb': ['Bb', 'Cm', 'Dm', 'Eb', 'F', 'Gm', 'Adim'],
    'Eb': ['Eb', 'Fm', 'Gm', 'Ab', 'Bb', 'Cm', 'Ddim'],
}

# Roman numeral notation
ROMAN_NUMERALS = ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°']

# Common progressions
COMMON_PROGRESSIONS = {
    'I-V-vi-IV': 'Pop progression (Axis)',
    'ii-V-I': 'Jazz turnaround',
    'I-vi-IV-V': '50s progression',
    'vi-IV-I-V': 'Pop/Rock variant',
    'I-IV-V': 'Basic Blues',
    'vi-ii-V-I': 'Circle progression',
    'I-iii-vi-IV': 'Axis progression',
    'V-vi': 'Deceptive cadence',
    'IV-V-I': 'Plagal cadence',
    'vii°-I': 'Leading tone resolution',
}

class ProgressionDetector:
    def __init__(self):
        self.audio_buffer = deque()
        self.lock = threading.Lock()
        self.is_running = False
        
        # Progression tracking
        self.chord_history = deque(maxlen=30)  # Store last 30 chord changes
        self.current_key = None
        self.key_confidence = 0
        self.last_chord = None
        self.chord_start_time = None
        self.last_timeline_update = datetime.now()
        
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
        if confidence > 0.6:
            return matched_chord, confidence
        else:
            return "Unknown", confidence
    
    def detect_key(self, recent_chords):
        """Dynamically detect the key from recent chord sequence"""
        if len(recent_chords) < 3:
            return None, 0
            
        key_scores = {}
        
        for key, key_chords in MAJOR_KEYS.items():
            score = 0
            for chord in recent_chords:
                # Clean chord name but keep important extensions
                base_chord = chord.replace('7', '').replace('maj', '')
                if base_chord in key_chords:
                    score += 1
                    
            key_scores[key] = score / len(recent_chords)
        
        best_key = max(key_scores, key=key_scores.get)
        confidence = key_scores[best_key]
        
        return best_key if confidence > 0.4 else None, confidence
    
    def chord_to_roman(self, chord, key):
        """Convert chord to Roman numeral in given key"""
        if not key or key not in MAJOR_KEYS:
            return chord
            
        key_chords = MAJOR_KEYS[key]
        
        # Handle different chord types
        if 'dim' in chord:
            base_chord = chord
        else:
            base_chord = chord.replace('7', '').replace('maj', '')
        
        try:
            index = key_chords.index(base_chord)
            roman = ROMAN_NUMERALS[index]
            
            # Add extensions back
            if 'dim' in chord:
                pass  # Already has ° symbol
            elif '7' in chord and 'maj7' not in chord:
                roman += '7'
            elif 'maj7' in chord:
                roman += 'M7'
                
            return roman
        except ValueError:
            # Non-diatonic chord
            return f"({chord})"
    
    def detect_progression_pattern(self, recent_romans):
        """Identify common progression patterns"""
        if len(recent_romans) < 2:
            return None
            
        # Check various lengths of patterns
        for length in range(4, 1, -1):  # Check 4, 3, 2 chord patterns
            if len(recent_romans) >= length:
                pattern = '-'.join(recent_romans[-length:])
                for prog_pattern, name in COMMON_PROGRESSIONS.items():
                    if pattern == prog_pattern:
                        return name
                    # Check if it's part of a longer pattern
                    if pattern in prog_pattern or prog_pattern in pattern:
                        return f"Part of {name}"
                        
        return None
    
    def print_timeline(self):
        """Print visual timeline of chord progression"""
        current_time = datetime.now()
        
        # Only update timeline every 2 seconds to reduce spam
        if (current_time - self.last_timeline_update).total_seconds() < 2:
            return
        self.last_timeline_update = current_time
        
        if len(self.chord_history) < 2:
            return
            
        # Clear screen for clean timeline display
        print("\n" * 3)
        print("="*70)
        print("🎼 HARMONIC PROGRESSION TIMELINE")
        print("="*70)
        
        # Get recent unique chords
        recent_chords = []
        seen_chords = set()
        
        for entry in reversed(list(self.chord_history)):
            chord = entry['chord']
            if chord not in seen_chords and chord != "Unknown":
                recent_chords.insert(0, entry)
                seen_chords.add(chord)
                if len(recent_chords) >= 8:
                    break
        
        if not recent_chords:
            print("🎵 Play some chords to see progression...")
            return
            
        # Detect key
        chord_names = [entry['chord'] for entry in recent_chords]
        detected_key, confidence = self.detect_key(chord_names)
        
        if detected_key and confidence > 0.5:
            self.current_key = detected_key
            self.key_confidence = confidence
        
        # Display key info
        if self.current_key:
            print(f"🗝️  Detected Key: {self.current_key} major (confidence: {self.key_confidence:.0%})")
            key_chords = ' - '.join(MAJOR_KEYS[self.current_key])
            print(f"📋 Diatonic chords: {key_chords}")
        else:
            print("🗝️  Key: Analyzing...")
        
        print()
        print("⏱️  CHORD PROGRESSION:")
        print("-" * 50)
        
        # Build visual timeline
        chord_line = ""
        roman_line = ""
        duration_line = ""
        roman_numerals = []
        
        for entry in recent_chords:
            chord = entry['chord']
            duration = entry.get('duration', 2.0)
            confidence = entry.get('confidence', 0.0)
            
            # Convert to Roman numeral
            if self.current_key:
                roman = self.chord_to_roman(chord, self.current_key)
                roman_numerals.append(roman)
            else:
                roman = chord
                roman_numerals.append(chord)
            
            # Create visual blocks
            block_size = max(3, min(8, int(duration * 2)))  # Scale duration
            
            chord_str = f"{chord:^{block_size}} "
            roman_str = f"{roman:^{block_size}} "
            duration_str = f"{duration:.1f}s{' ' * (block_size - 3)} "
            
            chord_line += chord_str
            roman_line += roman_str
            duration_line += duration_str
        
        print(f"Chords:   {chord_line}")
        print(f"Roman:    {roman_line}")
        print(f"Duration: {duration_line}")
        
        # Visual representation
        visual_line = ""
        for entry in recent_chords:
            duration = entry.get('duration', 2.0)
            block_size = max(3, min(8, int(duration * 2)))
            visual_line += "█" * block_size + " "
        print(f"Visual:   {visual_line}")
        
        # Pattern detection
        if len(roman_numerals) >= 3:
            pattern = self.detect_progression_pattern(roman_numerals)
            if pattern:
                print(f"\n🎵 Progression Pattern: {pattern}")
        
        # Show recent sequence
        if len(roman_numerals) >= 2:
            sequence = ' → '.join(roman_numerals[-6:])
            print(f"📊 Current sequence: {sequence}")
        
        # Statistics
        total_duration = sum([entry.get('duration', 0) for entry in recent_chords])
        print(f"⏰ Total playing time: {total_duration:.1f} seconds")
        print(f"🎹 Chords detected: {len(self.chord_history)}")
        
        print("="*70)
    
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
            if np.max(np.abs(y)) < 0.01:
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
            
            current_time = datetime.now()
            volume = np.sqrt(np.mean(y**2))
            
            # Print current detection (simplified)
            print(f"🎵 {chord:8} | Conf: {confidence:.2f} | Vol: {volume:.3f}")
            
            # Track chord changes for progression
            if chord != self.last_chord and chord != "Unknown" and confidence > 0.7:
                if self.last_chord and self.chord_start_time:
                    # Calculate duration of previous chord
                    duration = (current_time - self.chord_start_time).total_seconds()
                    # Update the last entry with duration
                    if self.chord_history:
                        self.chord_history[-1]['duration'] = duration
                
                # Add new chord to history
                self.chord_history.append({
                    'chord': chord,
                    'time': current_time,
                    'confidence': confidence,
                    'duration': 0
                })
                
                self.last_chord = chord
                self.chord_start_time = current_time
                
                # Update timeline display
                self.print_timeline()
            
        except Exception as e:
            print(f"Processing error: {e}")
    
    def audio_callback(self, indata, frames, time_info, status):
        if status:
            print(f"Audio status: {status}")
            
        with self.lock:
            # Add new audio data
            self.audio_buffer.extend(indata[:, 0])
            
            # Limit buffer size to prevent memory issues
            while len(self.audio_buffer) > FRAME_SIZE * 2:
                self.audio_buffer.popleft()
    
    def run(self):
        print("🎼 REAL-TIME HARMONIC PROGRESSION ANALYZER")
        print("="*60)
        print("🎹 Play chords clearly and hold them")
        print("🔍 Automatic key detection")
        print("📊 Real-time progression timeline")
        print("🎵 Pattern recognition")
        print("⏹️  Press Ctrl+C to exit")
        print("="*60)
        
        self.is_running = True
        
        try:
            # List available audio devices
            print("Available audio devices:")
            print(sd.query_devices())
            print("-" * 60)
            
            with sd.InputStream(callback=self.audio_callback, 
                              channels=1, 
                              samplerate=SAMPLE_RATE,
                              blocksize=1024):
                while self.is_running:
                    time.sleep(0.1)  # Frequent processing for responsiveness
                    self.process_audio()
                    
        except KeyboardInterrupt:
            print("\n🎵 Session ended!")
            if self.chord_history:
                print(f"📈 Total chords detected: {len(self.chord_history)}")
                if self.current_key:
                    print(f"🗝️  Final detected key: {self.current_key} major")
                
                # Show final progression summary
                if len(self.chord_history) >= 3:
                    final_chords = [entry['chord'] for entry in list(self.chord_history)[-6:]]
                    final_romans = []
                    if self.current_key:
                        final_romans = [self.chord_to_roman(chord, self.current_key) for chord in final_chords]
                    else:
                        final_romans = final_chords
                    
                    final_sequence = ' → '.join(final_romans)
                    print(f"🎼 Final progression: {final_sequence}")
                    
            self.is_running = False
        except Exception as e:
            print(f"Error: {e}")
            print("Try checking your microphone or audio settings")

if __name__ == "__main__":
    try:
        detector = ProgressionDetector()
        detector.run()
    except Exception as e:
        print(f"Failed to start analyzer: {e}")
        print("Make sure you have required packages: pip install numpy sounddevice librosa")