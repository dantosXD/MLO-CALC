const sqlite3 = require('sqlite3');
const path = require('path');

const dbPath = path.join(__dirname, 'features.db');
const db = new sqlite3.Database(dbPath);

db.get(
  `SELECT id, category, name, description, steps, passes, in_progress, dependencies, priority
   FROM features WHERE id = 12`,
  (err, row) => {
    if (err) {
      console.log(JSON.stringify({error: err.message}, null, 2));
    } else if (row) {
      const result = {
        id: row.id,
        category: row.category,
        name: row.name,
        description: row.description,
        steps: row.steps ? JSON.parse(row.steps) : [],
        passes: row.passes === 1,
        in_progress: row.in_progress === 1,
        dependencies: row.dependencies ? JSON.parse(row.dependencies) : [],
        priority: row.priority
      };
      console.log(JSON.stringify(result, null, 2));
    } else {
      console.log(JSON.stringify({error: "Feature #12 not found"}, null, 2));
    }
    db.close();
  }
);
