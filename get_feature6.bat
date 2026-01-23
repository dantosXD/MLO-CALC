@echo off
echo Feature #6 Query
echo ================
cd /d C:\Users\207ds\Desktop\Apps\MLO-CALC
node -e "const sqlite3 = require('sqlite3'); const db = new sqlite3.Database('./features.db'); db.get('SELECT id, category, name, description, steps FROM features WHERE id = 6', (err, row) => { if (err) console.error(err); else if (row) { console.log('ID:', row.id); console.log('Category:', row.category); console.log('Name:', row.name); console.log('Description:', row.description); console.log('Steps:', row.steps); } else console.log('Feature #6 not found'); db.close(); });"
