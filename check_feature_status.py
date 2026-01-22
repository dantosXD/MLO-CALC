import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()
cursor.execute('SELECT id, name, passes, in_progress FROM features WHERE id IN (11, 19)')
rows = cursor.fetchall()

for row in rows:
    print(f'ID: {row[0]}, Name: {row[1]}, Passes: {row[2]}, In-Progress: {row[3]}')

conn.close()
