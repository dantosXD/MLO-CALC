#!/usr/bin/env python3
import sqlite3
import json

conn = sqlite3.connect('features.db')
cursor = conn.cursor()

# Get feature #8 details
cursor.execute('SELECT id, priority, category, name, description, passes, in_progress FROM features WHERE id = 8')
result = cursor.fetchone()

if result:
    feature = {
        'id': result[0],
        'priority': result[1],
        'category': result[2],
        'name': result[3],
        'description': result[4],
        'passes': result[5],
        'in_progress': result[6]
    }
    print(json.dumps(feature, indent=2))
else:
    print(json.dumps({'error': 'Feature #8 not found'}))

conn.close()
