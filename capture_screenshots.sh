#!/bin/bash

# Screenshot capture script for Rails BDD Generator demo
echo "Capturing screenshots of demo application..."

# Wait for server to be ready
sleep 2

# Take screenshot of full page
echo "Taking screenshot..."
screencapture -T 1 "/Users/jpditri/rails-bdd-generator/demo_application_working.png"

echo "Screenshot saved to demo_application_working.png"