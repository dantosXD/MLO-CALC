import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()
cursor.execute('SELECT id, name, passes, in_progress, category, description FROM features WHERE id = 11')
result = cursor.fetchone()
if result:
    print(f"ID: {result[0]}")
    print(f"Name: {result[1]}")
    print(f"Passes: {result[2]}")
    print(f"In Progress: {result[3]}")
    print(f"Category: {result[4]}")
    print(f"Description: {result[5]}")
conn.close()
