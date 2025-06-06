import numpy as np
import time
from collections import deque, Counter
from datetime import datetime, timedelta
from live_chord_recognizer import ChordDetector, SAMPLE_RATE

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
MINOR_KEYS = {
    'A': ['Am', 'Bdim', 'C', 'Dm', 'Em', 'F', 'G'],
    'E': ['Em', 'F#dim', 'G', 'Am', 'Bm', 'C', 'D'],
    'B': ['Bm', 'C#dim', 'D', 'Em', 'F#m', 'G', 'A'],
    'F#': ['F#m', 'G#dim', 'A', 'Bm', 'C#m', 'D', 'E'],
    'C#': ['C#m', 'D#dim', 'E', 'F#m', 'G#m', 'A', 'B'],
    'D': ['Dm', 'Edim', 'F', 'Gm', 'Am', 'Bb', 'C'],
    'G': ['Gm', 'Adim', 'Bb', 'Cm', 'Dm', 'Eb', 'F'],
    'C': ['Cm', 'Ddim', 'Eb', 'Fm', 'Gm', 'Ab', 'Bb'],
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
        self.chord_detector = ChordDetector()
        self.is_running = False
        
        # Progression tracking
        self.chord_history = deque(maxlen=50)  # Store last 50 chord changes
        self.current_key = None
        self.key_confidence = 0
        self.last_chord = None
        self.chord_start_time = None
        self.session_start_time = None
        
        # Audio configuration
        self.channels = self.chord_detector.channels  # Get channels from ChordDetector



    def detect_key(self, recent_chords):
        """Smart key detection between major and minor scales with weighted scores"""
        if len(recent_chords) < 3:
            return None, 0

        def score_key(key_chords):
            score = 0
            for chord in recent_chords:
                base_chord = chord.replace('7', '').replace('maj', '')
                if base_chord in key_chords:
                    # Tonic & dominant chords are more significant
                    index = key_chords.index(base_chord)
                    weight = 2 if index in [0, 4] else 1
                    score += weight
            return score / len(recent_chords)

        key_scores = {}

        # Score all major keys
        for key, chords in MAJOR_KEYS.items():
            key_scores[f"{key} major"] = score_key(chords)

        # Score all minor keys
        for key, chords in MINOR_KEYS.items():
            key_scores[f"{key} minor"] = score_key(chords)

        best_key = max(key_scores, key=key_scores.get)
        best_score = key_scores[best_key]

        return (best_key, best_score) if best_score > 0.35 else (None, 0)
    
    def chord_to_roman(self, chord, key_info):
        """Convert chord to Roman numeral in given key (handles both major and minor)"""
        if not key_info:
            return chord
            
        # Parse key info (e.g., "C major" or "A minor")
        key_parts = key_info.split()
        if len(key_parts) != 2:
            return chord
            
        key_root = key_parts[0]
        key_type = key_parts[1]
        
        # Get the appropriate scale
        if key_type == "major":
            key_chords = MAJOR_KEYS.get(key_root, [])
        elif key_type == "minor":
            key_chords = MINOR_KEYS.get(key_root, [])
            # For minor keys, use different Roman numerals
            minor_romans = ['i', 'ii°', 'III', 'iv', 'v', 'VI', 'VII']
        else:
            return chord
        
        # Handle different chord types
        if 'dim' in chord:
            base_chord = chord
        else:
            base_chord = chord.replace('7', '').replace('maj', '')
        
        try:
            index = key_chords.index(base_chord)
            
            # Use appropriate Roman numerals for major vs minor
            if key_type == "major":
                roman = ROMAN_NUMERALS[index]
            else:  # minor key
                roman = minor_romans[index]
            
            # Add extensions back
            if 'dim' in chord:
                pass  # Already has ° symbol or handled in minor romans
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
    
    def print_session_summary(self):
        """Print final session summary with full timeline"""
        if len(self.chord_history) < 2:
            print("🎵 No chord progression detected in this session.")
            return
            
        print("\n" + "="*80)
        print("🎼 HARMONIC PROGRESSION SESSION SUMMARY")
        print("="*80)
        
        # Get all unique chords from session
        all_chords = []
        for entry in self.chord_history:
            chord = entry['chord']
            if chord != "Unknown":
                all_chords.append(chord)
        
        if not all_chords:
            print("🎵 No valid chords detected in this session.")
            return
            
            
        # Detect key from entire session
        detected_key, confidence = self.detect_key(all_chords)
        
        if detected_key and confidence > 0.5:
            self.current_key = detected_key            
            self.key_confidence = confidence
        
        # Display session info
        session_duration = (datetime.now() - self.session_start_time).total_seconds() if self.session_start_time else 0
        print(f"⏰ Session Duration: {session_duration:.1f} seconds")
        print(f"🎹 Total Chords Detected: {len(self.chord_history)}")
        print(f"🎵 Unique Chords: {len(set(all_chords))}")


        if self.current_key:
            print(f"🗝️  Detected Key: {self.current_key} (confidence: {self.key_confidence:.0%})")
            
            if "major" in self.current_key:
                key_root = self.current_key.replace(" major", "")
                scale = MAJOR_KEYS.get(key_root, [])
                roman_scale = ROMAN_NUMERALS
            elif "minor" in self.current_key:
                key_root = self.current_key.replace(" minor", "")
                scale = MINOR_KEYS.get(key_root, [])
                roman_scale = ['i', 'ii°', 'III', 'iv', 'v', 'VI', 'VII']
            else:
                scale = []
                roman_scale = []

            print(f"📋 Diatonic chords: {' - '.join(scale)}")
            
            # Show Roman numeral mapping
            if scale and roman_scale:
                print(f"🎼 Roman numerals: {' - '.join(roman_scale)}")
        else:
            print("🗝️  Key: Could not determine")
        
        print()
        print("⏱️  CHORD PROGRESSION TIMELINE:")
        print("-" * 70)
        
        # Build visual timeline
        chord_line = ""
        roman_line = ""
        duration_line = ""
        roman_numerals = []
        
        for entry in list(self.chord_history):
            chord = entry['chord']
            duration = entry.get('duration', 2.0)
            
            # Convert to Roman numeral
            if self.current_key:
                roman = self.chord_to_roman(chord, self.current_key)
                roman_numerals.append(roman)
            else:
                roman = chord
                roman_numerals.append(chord)
            
            # Create visual blocks (limit width for readability)
            block_size = max(3, min(8, int(duration * 2)))
            
            chord_str = f"{chord:^{block_size}} "
            roman_str = f"{roman:^{block_size}} "
            duration_str = f"{duration:.1f}s{' ' * (block_size - 3)} "
            
            chord_line += chord_str
            roman_line += roman_str
            duration_line += duration_str
            
            # Add line breaks for readability if line gets too long
            if len(chord_line) > 60:
                print(f"Chords:   {chord_line}")
                print(f"Roman:    {roman_line}")
                print(f"Duration: {duration_line}")
                print()
                chord_line = ""
                roman_line = ""
                duration_line = ""
        
        # Print remaining chords
        if chord_line:
            print(f"Chords:   {chord_line}")
            print(f"Roman:    {roman_line}")
            print(f"Duration: {duration_line}")
        
        # Visual representation
        print("\n📊 Visual Timeline:")
        visual_line = ""
        for entry in list(self.chord_history):
            duration = entry.get('duration', 2.0)
            block_size = max(1, min(6, int(duration)))
            visual_line += "█" * block_size + " "
            
            # Line break for long timelines
            if len(visual_line) > 60:
                print(f"      {visual_line}")
                visual_line = ""
        
        if visual_line:
            print(f"      {visual_line}")
        # Pattern analysis
        print("\n🎵 PROGRESSION ANALYSIS:")
        print("-" * 40)

        if len(roman_numerals) >= 3:
            pattern = self.detect_progression_pattern(roman_numerals)
            if pattern:
                print(f"🎼 Identified Pattern: {pattern}")

        # Show full sequence with both chord names and Roman numerals
        if len(roman_numerals) >= 2:
            chord_sequence = ' → '.join([entry['chord'] for entry in list(self.chord_history)])
            roman_sequence = ' → '.join(roman_numerals)
            print(f"📝 Chord Progression: {chord_sequence}")
            print(f"🎼 Roman Numeral Analysis: {roman_sequence}")

        # Roman numeral breakdown
        if self.current_key and roman_numerals:
            print(f"\n🎼 ROMAN NUMERAL BREAKDOWN:")
            print("-" * 40)
            unique_romans = list(dict.fromkeys(roman_numerals))  # Preserve order, remove duplicates
            
            for roman in unique_romans:
                # Find corresponding chord
                matching_chords = []
                for entry in self.chord_history:
                    chord = entry['chord']
                    if self.chord_to_roman(chord, self.current_key) == roman:
                        if chord not in matching_chords:
                            matching_chords.append(chord)
                
                chord_list = ", ".join(matching_chords)
                
                # Add functional analysis
                if "major" in self.current_key:
                    functions = {
                        'I': 'Tonic (home)', 'ii': 'Subdominant', 'iii': 'Mediant', 
                        'IV': 'Subdominant', 'V': 'Dominant', 'vi': 'Relative minor', 'vii°': 'Leading tone'
                    }
                else:  # minor key
                    functions = {
                        'i': 'Tonic (home)', 'ii°': 'Subdominant', 'III': 'Relative major', 
                        'iv': 'Subdominant', 'v': 'Dominant', 'VI': 'Submediant', 'VII': 'Subtonic'
                    }
                
                base_roman = roman.replace('7', '').replace('M7', '')
                function = functions.get(base_roman, 'Non-diatonic')
                print(f"   {roman:4} = {chord_list:8} ({function})")

        # Chord statistics with Roman numerals
        chord_counts = Counter(all_chords)
        print(f"\n📈 CHORD USAGE STATISTICS:")
        print("-" * 40)
        for chord, count in chord_counts.most_common(5):
            roman = self.chord_to_roman(chord, self.current_key) if self.current_key else "?"
            percentage = (count / len(all_chords)) * 100
            print(f"   {chord:6} ({roman:4}): {count} times ({percentage:.1f}%)")

        
        # Total playing time
        total_duration = sum([entry.get('duration', 0) for entry in self.chord_history])
        print(f"\n⏱️  Total Playing Time: {total_duration:.1f} seconds")
        
        print("="*80)
    
    def on_chord_detected(self, chord, confidence, volume):
        """Callback for chord detection - minimal real-time output"""
        current_time = datetime.now()
        
        # Simple real-time feedback (no timeline spam)
        if chord != "Unknown":
            print(f"🎵 {chord:8} | Conf: {confidence:.2f} | Vol: {volume:.3f}")
        
        # Track chord changes for progression (only high confidence chords)
        if (chord != self.last_chord and 
            chord != "Unknown" and 
            confidence > 0.7):  # Only track high confidence chords
            
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
            
            # Update key detection periodically (not every chord)
            if len(self.chord_history) % 3 == 0:  # Every 3 chords
                recent_chords = [entry['chord'] for entry in list(self.chord_history)[-8:]]
                detected_key, confidence = self.detect_key(recent_chords)
                if detected_key and confidence > 0.5:
                    if self.current_key != detected_key:
                        self.current_key = detected_key
                        self.key_confidence = confidence
                        print(f"🗝️  Key detected: {self.current_key}")
    
    def run(self):
        """Start the progression detector"""
        print("🎼 REAL-TIME HARMONIC PROGRESSION ANALYZER")
        print("="*60)
        print("🎹 Play chords clearly and hold them")
        print("🔍 Automatic key detection")
        print("📊 Timeline will be shown at session end")
        print("🎵 Pattern recognition")
        print(f"🎤 Using {self.channels} channel{'s' if self.channels > 1 else ''} audio input")
        print("⏹️  Press Ctrl+C to exit and see timeline")
        print("="*60)
        
        self.is_running = True
        self.session_start_time = datetime.now()
        
        try:
            # Start the chord detector with our callback
            self.chord_detector.start(on_chord_detected=self.on_chord_detected)
        except KeyboardInterrupt:
            pass  # Let the main handler deal with it
        except Exception as e:
            print(f"Error: {e}")
            print("Make sure your microphone is properly connected and configured")
        finally:
            self.stop()
    
    def stop(self):
        """Stop the progression detector and show final timeline"""
        print("\n🎵 Stopping progression analyzer...")
        self.is_running = False
        
        # Stop the chord detector
        self.chord_detector.stop()
        
        # Finalize last chord duration
        if self.chord_history and self.chord_start_time:
            duration = (datetime.now() - self.chord_start_time).total_seconds()
            self.chord_history[-1]['duration'] = duration
        
        # Clear screen for better visibility
        print("\n" * 3)
        
        # Show final session summary
        self.print_session_summary()
        
        # Additional harmonic progression analysis
        if len(self.chord_history) >= 2:
            print("\n🎼 HARMONIC PROGRESSION ANALYSIS")
            print("=" * 50)
            
            # Get all chords from the session
            all_chords = [entry['chord'] for entry in self.chord_history if entry['chord'] != "Unknown"]
            
            if all_chords:
                # Convert to Roman numerals if we have a key
                if self.current_key:
                    roman_numerals = [self.chord_to_roman(chord, self.current_key) for chord in all_chords]
                    print(f"\n📝 Full Progression in {self.current_key}:")
                    print("   " + " → ".join(roman_numerals))
                    
                    # Show chord relationships
                    print("\n🎵 Chord Relationships:")
                    for i in range(len(roman_numerals) - 1):
                        print(f"   {roman_numerals[i]} → {roman_numerals[i+1]}")
                    
                    # Identify common patterns
                    print("\n🎼 Common Patterns Found:")
                    for length in range(4, 1, -1):
                        if len(roman_numerals) >= length:
                            pattern = "-".join(roman_numerals[-length:])
                            for prog_pattern, name in COMMON_PROGRESSIONS.items():
                                if pattern == prog_pattern:
                                    print(f"   • {name}: {pattern}")
                                elif pattern in prog_pattern:
                                    print(f"   • Part of {name}: {pattern}")
                
                # Show chord frequency
                chord_counts = Counter(all_chords)
                print("\n📊 Chord Frequency:")
                for chord, count in chord_counts.most_common():
                    percentage = (count / len(all_chords)) * 100
                    print(f"   {chord}: {count} times ({percentage:.1f}%)")
        
        print("\n🎵 Session ended. Thank you for playing!")
        print("=" * 50)

# Standalone usage
if __name__ == "__main__":
    print("🎼 Live Chord Progression Detector")
    print("=" * 50)
    
    detector = ProgressionDetector()
    try:
        detector.run()
    except KeyboardInterrupt:
        pass  # Let the finally block handle cleanup
    except Exception as e:
        print(f"Failed to start analyzer: {e}")
        print("Make sure you have required packages: pip install numpy sounddevice librosa")
    finally:
        print("\n🎵 Stopping progression analyzer...")
        detector.stop()