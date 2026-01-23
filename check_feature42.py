import sqlite3

conn = sqlite3.connect('features.db')
cursor = conn.cursor()

print("=" * 70)
print("FEATURE #42 STATUS CHECK")
print("=" * 70)

cursor.execute('SELECT id, category, name, passes, in_progress FROM features WHERE id = 42')
row = cursor.fetchone()

if row:
    print(f"\nFeature #{row[0]}: {row[2]}")
    print(f"Category: {row[1]}")
    print(f"Passes: {row[3]}")
    print(f"In Progress: {row[4]}")
else:
    print("\n❌ Feature #42 does NOT exist in database")

print("\n" + "=" * 70)
print("FEATURES AROUND #42")
print("=" * 70)

cursor.execute('SELECT id, name, passes, in_progress FROM features WHERE id BETWEEN 40 AND 45 ORDER BY id')
rows = cursor.fetchall()

for row in rows:
    status = "✅ PASS" if row[2] else "🔄 PENDING"
    in_progress = " [IN PROGRESS]" if row[3] else ""
    print(f"Feature #{row[0]}: {row[1]} - {status}{in_progress}")

conn.close()
