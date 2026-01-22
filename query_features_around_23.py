import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()

# Query features around ID 23
cursor.execute('SELECT id, priority, category, name, passes, in_progress FROM features WHERE id BETWEEN 20 AND 26 ORDER BY id')
results = cursor.fetchall()

print("Features around ID #23:")
print("=" * 100)
for row in results:
    print(f"ID: {row[0]:2d} | Priority: {row[1]:3d} | Category: {row[2]:20s} | Name: {row[3]:40s} | Passes: {row[4]} | In Progress: {row[5]}")

conn.close()
