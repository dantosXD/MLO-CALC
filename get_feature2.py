import sqlite3
import json

conn = sqlite3.connect('features.db')
cursor = conn.cursor()
cursor.execute('SELECT * FROM features WHERE id = 2')
result = cursor.fetchone()

if result:
    feature = {
        'id': result[0],
        'priority': result[1],
        'category': result[2],
        'name': result[3],
        'description': result[4],
        'steps': json.loads(result[5]) if result[5] else [],
        'passes': result[6],
        'in_progress': result[7],
        'dependencies': json.loads(result[8]) if result[8] else []
    }
    print(json.dumps(feature, indent=2))
else:
    print('{"error": "Feature #2 not found"}')

conn.close()
