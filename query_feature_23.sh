#!/bin/bash
# Simple script to display feature 23 info from the database file

echo "Attempting to read features.db..."
echo "Looking for Feature #23..."
echo ""

# Try using grep on the binary database file
grep -a "23" features.db | head -5
