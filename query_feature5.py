import sqlite3
import json

conn = sqlite3.connect('features.db')
cursor = conn.cursor()
cursor.execute('SELECT id, priority, category, name, description, steps, passes, in_progress FROM features WHERE id = 5')
result = cursor.fetchone()

if result:
    print(f'ID: {result[0]}')
    print(f'Priority: {result[1]}')
    print(f'Category: {result[2]}')
    print(f'Name: {result[3]}')
    print(f'Description: {result[4]}')
    print(f'Steps: {result[5]}')
    print(f'Passing: {result[6]}')
    print(f'In Progress: {result[7]}')
else:
    print('Feature #5 not found')

conn.close()
