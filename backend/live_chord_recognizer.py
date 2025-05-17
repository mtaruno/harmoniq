
import numpy as np
import sounddevice as sd
import librosa
import librosa.display
import threading
import time

# Audio settings
SAMPLE_RATE = 22050
FRAME_DURATION = 2  # seconds
FRAME_SIZE = SAMPLE_RATE * FRAME_DURATION

# Chord templates: simplified major and minor triads
CHORD_TEMPLATES = {
    'C':   [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0],
    'C#m': [0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
    'D':   [0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0],
    'Dm':  [0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0],
    'E':   [0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0],
    'Em':  [0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    'F':   [1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0],
    'G':   [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    'A':   [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1],
    'Am':  [0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1],
    'B':   [0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0],
}

def match_chord(chroma):
    max_score = -1
    matched_chord = "Unknown"
    for chord, template in CHORD_TEMPLATES.items():
        score = np.dot(chroma, template)
        if score > max_score:
            max_score = score
            matched_chord = chord
    return matched_chord

def process_audio(audio_buffer):
    y = np.array(audio_buffer, dtype=np.float32)
    chroma = librosa.feature.chroma_cqt(y=y, sr=SAMPLE_RATE)
    avg_chroma = np.mean(chroma, axis=1)
    matched = match_chord(avg_chroma)
    print(f"Detected Chord: {matched}")

def audio_callback(indata, frames, time_info, status):
    audio_buffer.extend(indata[:, 0])

# Create global buffer
audio_buffer = []

def stream_and_detect():
    with sd.InputStream(callback=audio_callback, channels=1, samplerate=SAMPLE_RATE):
        while True:
            time.sleep(FRAME_DURATION)
            if len(audio_buffer) >= FRAME_SIZE:
                buffer_copy = audio_buffer[:FRAME_SIZE]
                del audio_buffer[:FRAME_SIZE]
                process_audio(buffer_copy)

if __name__ == "__main__":
    print("🎶 Harmoniq Live Chord Recognizer (Prototype)")
    print("Start playing... (Ctrl+C to exit)")
    try:
        stream_and_detect()
    except KeyboardInterrupt:
        print("\nStopped.")