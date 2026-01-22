import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()

# Get feature #31
cursor.execute('SELECT id, priority, category, name, description, steps, passes, in_progress FROM features WHERE id = 31')
feature = cursor.fetchone()

if feature:
    print(f"Feature ID: {feature[0]}")
    print(f"Priority: {feature[1]}")
    print(f"Category: {feature[2]}")
    print(f"Name: {feature[3]}")
    print(f"Description: {feature[4]}")
    print(f"Steps: {feature[5]}")
    print(f"Passing: {feature[6]}")
    print(f"In Progress: {feature[7]}")
else:
    print("Feature #31 not found")

conn.close()
