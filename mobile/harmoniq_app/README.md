# Harmoniq Flutter App

A beautiful, real-time chord progression detection and analysis app for aspiring pianists and composers.

## Features

- 🎵 **Real-time Chord Detection**: Live chord recognition with confidence scoring
- 🗝️ **Key Signature Analysis**: Automatic key detection and Roman numeral notation
- 📊 **Session Analytics**: Detailed progression analysis and chord frequency charts
- 💾 **Session History**: Save and review past sessions
- 🎨 **Cute UI Design**: Pastel colors and delightful animations
- ⚙️ **Customizable Settings**: Adjustable confidence thresholds and preferences

## Architecture

The app consists of two main components:

1. **Flutter Frontend** (`mobile/harmoniq_app/`): Beautiful UI with real-time chord visualization
2. **Python Backend** (`backend/`): Audio processing and chord detection via WebSocket

## Setup Instructions

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Python 3.8+ with virtual environment
- iOS Simulator or physical iOS device

### Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Activate your virtual environment:
```bash
source .venv/bin/activate  # On macOS/Linux
# or
.venv\Scripts\activate     # On Windows
```

3. Install Python dependencies:
```bash
pip install -r requirements.txt
```

4. Test the chord detection (optional):
```bash
python live_chord_progression.py
```

5. Start the WebSocket server:
```bash
python websocket_server.py
```

The server will start on `http://localhost:8000` with WebSocket endpoint at `ws://localhost:8000/ws`.

### Flutter App Setup

1. Navigate to the Flutter app directory:
```bash
cd mobile/harmoniq_app
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Usage

### Starting a Session

1. **Launch the app** and tap the large "Start Session" button on the home screen
2. **Grant microphone permissions** when prompted
3. **Begin playing piano** - the app will automatically detect chords in real-time
4. **Adjust confidence threshold** using the slider during the session
5. **Stop the session** when finished to view detailed analysis

### Understanding the Interface

#### Home Screen
- **Start Session Button**: Large, animated button to begin chord detection
- **Recent Sessions**: Quick access to your 5 most recent sessions
- **Settings Icon**: Access app preferences and configuration

#### Live Session Screen
- **Current Chord Display**: Large chord chip showing the most recent detection
- **Confidence Slider**: Adjust detection sensitivity in real-time
- **Recent Chords Timeline**: Horizontal scrolling list of detected chords
- **Session Stats**: Duration, chord count, and unique chords
- **Volume Indicator**: Visual feedback for microphone input

#### Session Summary Screen
- **Session Overview**: Duration, total chords, unique chords, detected key
- **Chord Timeline**: Visual representation of your progression
- **Frequency Chart**: Bar chart showing most-used chords
- **Roman Numeral Analysis**: Theoretical analysis in the detected key

### Chord Chip Color Coding

- **Pink**: Major chords
- **Blue**: Minor chords  
- **Purple**: Seventh chords
- **Peach**: Diminished chords
- **Gray**: Unknown/low confidence chords

### Confidence Levels

- **Green Border**: High confidence (80%+)
- **Orange Border**: Medium confidence (65-80%)
- **Red Border**: Low confidence (<65%)

## Settings

### Audio Settings
- **Default Confidence Threshold**: Set your preferred detection sensitivity
- **Audio Input Device**: Choose microphone (auto-selected on mobile)

### Display Settings
- **Dark Mode**: Toggle between light and dark themes
- **Show Roman Numerals**: Display harmonic analysis on chord chips

### Session Settings
- **Auto-save Sessions**: Automatically save session data to local database

## Technical Details

### Database Schema

The app uses SQLite for local storage with the following tables:

- **Session**: Stores session metadata (duration, key, chord counts)
- **ChordDetection**: Individual chord detections with timestamps
- **FavoriteProgression**: Saved chord progressions (future feature)
- **Settings**: User preferences and configuration

### WebSocket Communication

The Flutter app communicates with the Python backend via WebSocket messages:

- `start_session`: Begin chord detection
- `stop_session`: End current session
- `update_threshold`: Change confidence threshold
- `chord_detected`: Real-time chord detection data
- `key_detected`: Key signature detection
- `session_summary`: Final session analysis

### State Management

The app uses Provider pattern for state management:

- **SessionProvider**: Manages active sessions and real-time data
- **SettingsProvider**: Handles user preferences and persistence

## Troubleshooting

### Common Issues

1. **"Failed to start session"**
   - Ensure the Python WebSocket server is running
   - Check that `websocket_server.py` is accessible on localhost:8000

2. **No chord detection**
   - Verify microphone permissions are granted
   - Check audio input levels in the volume indicator
   - Try lowering the confidence threshold
   - Ensure you're playing chords clearly and holding them

3. **App crashes on startup**
   - Run `flutter clean && flutter pub get`
   - Ensure all dependencies are properly installed

### Performance Tips

- Use in a quiet environment for better detection accuracy
- Play chords clearly and hold them for at least 1-2 seconds
- Adjust confidence threshold based on your playing style
- Close other audio applications that might interfere

## Future Features

- ⭐ **Favorites Management**: Save and organize favorite progressions
- 🎯 **Pattern Recognition**: Match your progressions to famous songs
- 🔄 **Cloud Sync**: Backup sessions across devices
- 🎼 **MIDI Support**: Connect MIDI keyboards for direct input
- 📱 **Apple Watch Integration**: Quick session controls
- 🎵 **Audio Playback**: Play back detected chord progressions

## Contributing

This app is part of the Harmoniq project. For contributions or issues, please refer to the main project repository.

## License

Copyright © 2024 Harmoniq. All rights reserved.
