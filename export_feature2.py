import sqlite3
import json

conn = sqlite3.connect('features.db')
cursor = conn.cursor()
cursor.execute('SELECT id, category, name, description, steps, passes, in_progress, dependencies, priority FROM features WHERE id = 2')
row = cursor.fetchone()

if row:
    feature = {
        'id': row[0],
        'category': row[1],
        'name': row[2],
        'description': row[3],
        'steps': row[4],
        'passes': row[5],
        'in_progress': row[6],
        'dependencies': row[7],
        'priority': row[8]
    }
    with open('feature2.json', 'w') as f:
        json.dump(feature, f, indent=2)
    print(json.dumps(feature, indent=2))
else:
    print('{"error": "Feature #2 not found"}')

conn.close()
