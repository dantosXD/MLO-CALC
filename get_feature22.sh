#!/bin/bash
# Get Feature #22 details using Flutter

cd /c/Users/207ds/Desktop/Apps/MLO-CALC

flutter --version 2>/dev/null || echo "Flutter check"

# Try to read the database using hexdump or strings
strings features.db | grep -A 20 "Feature #22" | head -30
