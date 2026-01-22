import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()
cursor.execute('SELECT * FROM features WHERE id = 23')
result = cursor.fetchone()
if result:
    print(f"ID: {result[0]}")
    print(f"Priority: {result[1]}")
    print(f"Category: {result[2]}")
    print(f"Name: {result[3]}")
    print(f"Description: {result[4]}")
    print(f"Steps: {result[5]}")
    print(f"Passes: {result[6]}")
    print(f"In Progress: {result[7]}")
    print(f"Dependencies: {result[8]}")
else:
    print("Feature #23 not found")
conn.close()
