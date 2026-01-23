const { execSync } = require('child_process');
const fs = require('fs');

try {
  const output = execSync('py get_feature13.py', { encoding: 'utf8' });
  console.log(output);
  fs.writeFileSync('feature13.json', output);
} catch (error) {
  console.error('Error:', error.message);
}
