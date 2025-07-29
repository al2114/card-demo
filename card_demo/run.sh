#!/bin/bash

# Enable web support
flutter config --enable-web

# Get dependencies
flutter pub get

# Build for web
flutter build web --release

# Serve the web app
cd build/web
python3 -m http.server 5000 