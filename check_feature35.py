import sqlite3

def check_feature_35():
    conn = sqlite3.connect('features.db')
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT id, category, name, description, steps, passes, in_progress
        FROM features WHERE id = 35
    """)
    
    feature = cursor.fetchone()
    if feature:
        print(f"Feature #35: {feature[2]}")
        print(f"Category: {feature[1]}")
        print(f"Description: {feature[3]}")
        print(f"Status: {'PASSING' if feature[5] else 'FAILING'}")
        print(f"\nVerification Steps:")
        for i, step in enumerate(eval(feature[4]), 1):
            print(f"  {i}. {step}")
    
    conn.close()

check_feature_35()
