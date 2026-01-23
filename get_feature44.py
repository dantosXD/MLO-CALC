import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()

cursor.execute("""
    SELECT id, priority, category, name, description, steps, passes, in_progress, dependencies
    FROM features
    WHERE id = 44
""")

result = cursor.fetchone()

if result:
    print(f"Feature ID: {result[0]}")
    print(f"Priority: {result[1]}")
    print(f"Category: {result[2]}")
    print(f"Name: {result[3]}")
    print(f"\nDescription:\n{result[4]}")
    print(f"\nSteps:\n{result[5]}")
    print(f"\nPassing: {result[6]}")
    print(f"In Progress: {result[7]}")
    print(f"\nDependencies: {result[8]}")
else:
    print("Feature #44 not found")

conn.close()
