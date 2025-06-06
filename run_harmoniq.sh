#!/bin/bash

# Harmoniq Startup Script
# This script starts both the Python backend and Flutter app

echo "🎼 Starting Harmoniq..."
echo "================================"

# Check if we're in the right directory
if [ ! -d "backend" ] || [ ! -d "mobile" ]; then
    echo "❌ Error: Please run this script from the harmoniq root directory"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
echo "🔍 Checking dependencies..."

if ! command_exists python3; then
    echo "❌ Python 3 is not installed"
    exit 1
fi

if ! command_exists flutter; then
    echo "❌ Flutter is not installed"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "backend/.venv" ]; then
    echo "❌ Virtual environment not found in backend/.venv"
    echo "Please create a virtual environment and install dependencies:"
    echo "  cd backend"
    echo "  python3 -m venv .venv"
    echo "  source .venv/bin/activate"
    echo "  pip install -r requirements.txt"
    exit 1
fi

echo "✅ Dependencies check passed"

# Start backend server
echo ""
echo "🚀 Starting Python WebSocket server..."
cd backend

# Activate virtual environment and start server in background
source .venv/bin/activate
python websocket_server.py &
BACKEND_PID=$!

echo "✅ Backend server started (PID: $BACKEND_PID)"
echo "🔗 WebSocket endpoint: ws://localhost:8000/ws"

# Wait a moment for server to start
sleep 3

# Check if server is running
if ! curl -s http://localhost:8000/health > /dev/null; then
    echo "❌ Backend server failed to start"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

echo "✅ Backend server is healthy"

# Start Flutter app
echo ""
echo "📱 Starting Flutter app..."
cd ../mobile/harmoniq_app

# Install dependencies if needed
if [ ! -d ".dart_tool" ]; then
    echo "📦 Installing Flutter dependencies..."
    flutter pub get
fi

# Run Flutter app
echo "🎵 Launching Harmoniq app..."
flutter run

# Cleanup function
cleanup() {
    echo ""
    echo "🛑 Shutting down Harmoniq..."
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null
        echo "✅ Backend server stopped"
    fi
    echo "👋 Goodbye!"
}

# Set trap to cleanup on script exit
trap cleanup EXIT INT TERM

# Wait for Flutter app to exit
wait
