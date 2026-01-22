import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()
cursor.execute('SELECT id, priority, category, name, description, steps FROM features WHERE id = 32')
result = cursor.fetchone()
if result:
    print(f'ID: {result[0]}')
    print(f'Priority: {result[1]}')
    print(f'Category: {result[2]}')
    print(f'Name: {result[3]}')
    print(f'Description: {result[4]}')
    print(f'Steps: {result[5]}')
else:
    print('Feature #32 not found')
conn.close()
