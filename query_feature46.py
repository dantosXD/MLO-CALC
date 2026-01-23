#!/usr/bin/env python3
import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()

# Query all features starting from ID 45
cursor.execute('''
    SELECT id, priority, category, name, description, passes, in_progress
    FROM features
    WHERE id >= 45
    ORDER BY id
''')

rows = cursor.fetchall()

print("=" * 80)
print("FEATURES FROM ID 45+")
print("=" * 80)

for row in rows:
    id, priority, category, name, description, passes, in_progress = row
    print(f"\nID: {id}")
    print(f"Priority: {priority}")
    print(f"Category: {category}")
    print(f"Name: {name}")
    print(f"Passing: {passes}")
    print(f"In Progress: {in_progress}")
    print(f"Description: {description[:100]}...")
    print("-" * 80)

conn.close()
