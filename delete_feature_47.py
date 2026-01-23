import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()

# Delete the test feature
cursor.execute("DELETE FROM features WHERE id = 47")
conn.commit()

print(f"Deleted Feature #47 (Test Feature)")
print(f"Rows affected: {cursor.rowcount}")

# Verify deletion
cursor.execute("SELECT COUNT(*) FROM features")
total = cursor.fetchone()[0]

cursor.execute("SELECT COUNT(*) FROM features WHERE passes = 1")
passing = cursor.fetchone()[0]

print(f"\nUpdated Stats:")
print(f"Total Features: {total}")
print(f"Passing: {passing}/{total} ({passing/total*100:.1f}%)")

conn.close()
