import sqlite3
import json

conn = sqlite3.connect('features.db')
cursor = conn.cursor()

cursor.execute("""
    SELECT id, category, name, description, steps, passes, in_progress, dependencies, priority
    FROM features
    WHERE id = 20
""")

feature = cursor.fetchone()

if feature:
    result = {
        "id": feature[0],
        "category": feature[1],
        "name": feature[2],
        "description": feature[3],
        "steps": feature[4],
        "passes": feature[5],
        "in_progress": feature[6],
        "dependencies": feature[7],
        "priority": feature[8]
    }
    print(json.dumps(result, indent=2))
else:
    print("Feature #20 not found")

conn.close()
