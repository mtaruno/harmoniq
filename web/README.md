

## Development Setup
### Installation
1. Clone the repository
```bash
git clone https://github.com/mtaruno/harmoniq.git
cd harmoniq
```

2. Install dependencies
```bash
npm install
```

Note: Since this is a Node.js/TypeScript project, we don't use virtual environments. Rather the dependencies are managed through `package.json`. If you need a clean development environment, you can:
```bash
# Remove existing dependencies
rm -rf node_modules package-lock.json

# Reinstall dependencies
npm install
```

3. Build the project
```bash
npm run build
```
4. Start the development server
```bash
npm run dev
```
5. Open your browser and navigate to `http://localhost:3000`

### Available Scripts
- `npm run dev`: Start the development server with hot reloading
`npm run build`: Build the TypeScript files and copy assets to the dist folder
- `npm start`: Start the production server
- `npm run watch`: Watch for TypeScript changes and recompile

## Project Structure
```
harmoniq/
├── dist/                  # Compiled JavaScript files
├── public/                # Static assets
│   ├── css/               # CSS files
│   ├── js/                # JavaScript files (for reference)
│   └── index.html         # Main HTML file
├── src/                   # TypeScript source files
│   ├── public/            # TypeScript files for public assets
│   │   ├── js/            # TypeScript files for JavaScript
│   │   └── css/           # TypeScript files for CSS (if needed)
│   └── server/            # Server-side TypeScript files
├── copy-assets.js         # Script to copy assets to dist folder
├── package.json           # Project configuration
└── tsconfig.json          # TypeScript configuration
```