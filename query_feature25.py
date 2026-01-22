#!/usr/bin/env python3
import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()
cursor.execute('SELECT id, priority, name, description, category FROM features WHERE id = 25')
result = cursor.fetchone()
if result:
    print(f"ID: {result[0]}")
    print(f"Priority: {result[1]}")
    print(f"Name: {result[2]}")
    print(f"Description: {result[3]}")
    print(f"Category: {result[4]}")
else:
    print("Feature #25 not found")
conn.close()
