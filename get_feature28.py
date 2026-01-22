import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()

# Get feature #28
cursor.execute("SELECT id, priority, category, name, description, steps, passes, in_progress FROM features WHERE id = 28")
feature = cursor.fetchone()

if feature:
    print(f"Feature ID: {feature[0]}")
    print(f"Priority: {feature[1]}")
    print(f"Category: {feature[2]}")
    print(f"Name: {feature[3]}")
    print(f"\nDescription:")
    print(feature[4])
    print(f"\nSteps:")
    print(feature[5])
    print(f"\nPassing: {feature[6]}")
    print(f"In Progress: {feature[7]}")
else:
    print("Feature #28 not found")

conn.close()
