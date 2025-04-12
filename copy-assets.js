const fs = require('fs');
const path = require('path');

// Create dist/public directory if it doesn't exist
const distPublicDir = path.join(__dirname, 'dist', 'public');
if (!fs.existsSync(distPublicDir)) {
    fs.mkdirSync(distPublicDir, { recursive: true });
}

// Create dist/public/css directory if it doesn't exist
const distCssDir = path.join(distPublicDir, 'css');
if (!fs.existsSync(distCssDir)) {
    fs.mkdirSync(distCssDir, { recursive: true });
}

// Copy HTML file
fs.copyFileSync(
    path.join(__dirname, 'public', 'index.html'),
    path.join(distPublicDir, 'index.html')
);

// Copy CSS file
fs.copyFileSync(
    path.join(__dirname, 'public', 'css', 'styles.css'),
    path.join(distCssDir, 'styles.css')
);

console.log('Assets copied to dist folder successfully!'); 