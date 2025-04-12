"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const body_parser_1 = __importDefault(require("body-parser"));
const path_1 = __importDefault(require("path"));
const app = (0, express_1.default)();
const port = process.env.PORT ? parseInt(process.env.PORT) : 3000;
// Middleware
app.use((0, cors_1.default)());
app.use(body_parser_1.default.json());
app.use(express_1.default.static(path_1.default.join(__dirname, '../../public')));
// Routes
app.get('/', (req, res) => {
    res.sendFile(path_1.default.join(__dirname, '../../public/index.html'));
});
// API endpoints
app.post('/api/favorites', (req, res) => {
    // Handle saving favorites to a file or database
    res.json({ success: true });
});
app.get('/api/favorites', (req, res) => {
    // Handle retrieving favorites from a file or database
    res.json([]);
});
// Start server
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
//# sourceMappingURL=index.js.map