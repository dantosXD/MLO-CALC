const fs = require('fs');
const path = require('path');

// Read the database as binary
const dbPath = './features.db';
const buffer = fs.readFileSync(dbPath);

// Simple SQLite database reader for features table
// This is a basic implementation - looks for the features table
function findFeature(buffer, featureId) {
  const str = buffer.toString('utf8');
  const patterns = [
    new RegExp(`Feature.*?${featureId}.*?Calculator`, 'i'),
  ];

  // Try to extract feature info by looking for patterns
  const lines = str.split('\x00');
  for (let line of lines) {
    if (line.includes(`Feature #${featureId}`) || line.includes(`feature${featureId}`)) {
      console.log("Found:", line);
    }
  }
}

// Alternative: Use better-sqlite3 if available
try {
  const Database = require('better-sqlite3');
  const db = new Database('./features.db', { readonly: true });
  const row = db.prepare('SELECT id, category, name, description, steps, passes, in_progress FROM features WHERE id = ?').get(6);
  if (row) {
    console.log(JSON.stringify(row, null, 2));
    fs.writeFileSync('feature6.json', JSON.stringify(row, null, 2));
    console.log('\nExported to feature6.json');
  } else {
    console.log('Feature #6 not found');
  }
  db.close();
} catch (e) {
  console.log('better-sqlite3 not available, trying manual extraction...');
  console.log('Error:', e.message);
}
