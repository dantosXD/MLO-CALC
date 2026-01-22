import sqlite3
import json

conn = sqlite3.connect('features.db')
cursor = conn.cursor()
cursor.execute('SELECT * FROM features WHERE id = 34')
result = cursor.fetchone()
if result:
    print(json.dumps({
        'id': result[0],
        'priority': result[1],
        'category': result[2],
        'name': result[3],
        'description': result[4],
        'steps': result[5],
        'passes': result[6],
        'in_progress': result[7]
    }, indent=2))
else:
    print('Feature #34 not found')
conn.close()
