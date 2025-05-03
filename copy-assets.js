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

// Create dist/public/js directory if it doesn't exist
const distJsDir = path.join(distPublicDir, 'js');
if (!fs.existsSync(distJsDir)) {
    fs.mkdirSync(distJsDir, { recursive: true });
}

// Copy HTML file
fs.copyFileSync(
    path.join(__dirname, 'public', 'index.html'),
    path.join(distPublicDir, 'index.html')
);

// Copy CSS file if it exists
const cssSourcePath = path.join(__dirname, 'public', 'css', 'styles.css');
if (fs.existsSync(cssSourcePath)) {
    fs.copyFileSync(
        cssSourcePath,
        path.join(distCssDir, 'styles.css')
    );
} else {
    console.log('Note: styles.css not found, skipping CSS copy');
}

// Copy all JS files from public/js to dist/public/js
const jsSourceDir = path.join(__dirname, 'public', 'js');
if (fs.existsSync(jsSourceDir)) {
    const jsFiles = fs.readdirSync(jsSourceDir);
    jsFiles.forEach(file => {
        if (file.endsWith('.js')) {
            fs.copyFileSync(
                path.join(jsSourceDir, file),
                path.join(distJsDir, file)
            );
        }
    });
    console.log(`Copied ${jsFiles.filter(f => f.endsWith('.js')).length} JavaScript files`);
}

console.log('Assets copied to dist folder successfully!');