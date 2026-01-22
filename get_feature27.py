#!/usr/bin/env python3
import sqlite3
import json

conn = sqlite3.connect('features.db')
cursor = conn.cursor()
cursor.execute('SELECT id, priority, category, name, description, steps FROM features WHERE id = 27')
row = cursor.fetchone()

if row:
    print(f'ID: {row[0]}')
    print(f'Priority: {row[1]}')
    print(f'Category: {row[2]}')
    print(f'Name: {row[3]}')
    print(f'Description: {row[4]}')
    steps = json.loads(row[5]) if row[5] else []
    print(f'Steps:')
    for i, step in enumerate(steps, 1):
        print(f'  {i}. {step}')
else:
    print('Feature #27 not found')

conn.close()
