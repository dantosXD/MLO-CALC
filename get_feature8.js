const sqlite3 = require('sqlite3');
const db = new sqlite3.Database('./features.db');

db.get("SELECT id, category, name, description, steps, passes, in_progress, dependencies, priority FROM features WHERE id = 8", (err, row) => {
  if (err) {
    console.error(err);
  } else if (row) {
    console.log(JSON.stringify(row, null, 2));
  } else {
    console.log(JSON.stringify({error: "Feature #8 not found"}));
  }
  db.close();
});
