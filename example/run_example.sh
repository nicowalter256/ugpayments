#!/bin/bash

# UgPayments Example App Runner
# This script helps you run the example app with proper setup

echo "🚀 UgPayments Example App"
echo "=========================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    echo "   Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check Flutter version
echo "📱 Flutter version:"
flutter --version

echo ""
echo "📦 Installing dependencies..."
flutter pub get

echo ""
echo "🔧 Configuration Check:"
echo "Please make sure you have:"
echo "1. Updated lib/config.dart with your PesaPal credentials"
echo "2. Set the correct environment (sandbox/production)"
echo "3. Configured callback URLs and notification IDs"
echo ""

# Check if config is properly set up
if grep -q "your_sandbox_bearer_token_here" lib/config.dart; then
    echo "⚠️  WARNING: You're using placeholder credentials!"
    echo "   Please update lib/config.dart with your actual PesaPal credentials."
    echo ""
fi

echo "🎯 Available commands:"
echo "  flutter run                    - Run the app"
echo "  flutter run --debug            - Run in debug mode"
echo "  flutter run --release          - Run in release mode"
echo "  flutter test                   - Run tests"
echo "  flutter analyze               - Analyze code"
echo ""

echo "📱 Running the app..."
echo "Press Ctrl+C to stop"
echo ""

# Run the app
flutter run
