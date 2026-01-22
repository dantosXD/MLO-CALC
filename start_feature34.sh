#!/bin/bash
cd /c/Users/207ds/Desktop/Apps/MLO-CALC

# Kill any existing Flutter web processes on port 8089
pkill -f "flutter.*web.*8089" 2>/dev/null
sleep 2

# Start Flutter web server on port 8089
nohup flutter run -d chrome --web-port 8089 > flutter-web-feature34.log 2>&1 &

echo "Flutter web server starting on port 8089..."
echo "Log file: flutter-web-feature34.log"
sleep 5
tail -20 flutter-web-feature34.log
