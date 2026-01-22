import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()
cursor.execute('SELECT * FROM features WHERE id = 21')
row = cursor.fetchone()

if row:
    print(f'Feature ID: {row[0]}')
    print(f'Priority: {row[1]}')
    print(f'Category: {row[2]}')
    print(f'Name: {row[3]}')
    print(f'Description: {row[4]}')
    print(f'Steps:')
    import json
    steps = json.loads(row[5])
    for i, step in enumerate(steps, 1):
        print(f'  {i}. {step}')
    print(f'Passes: {row[6]}')
    print(f'In-Progress: {row[7]}')
else:
    print('Feature #21 not found')

conn.close()
