import express, { Request, Response } from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import path from 'path';

const app = express();
const port: number = process.env.PORT ? parseInt(process.env.PORT) : 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, '../../public')));

// Routes
app.get('/', (req: Request, res: Response) => {
    res.sendFile(path.join(__dirname, '../../public/index.html'));
});

// API endpoints
app.post('/api/favorites', (req: Request, res: Response) => {
    // Handle saving favorites to a file or database
    res.json({ success: true });
});

app.get('/api/favorites', (req: Request, res: Response) => {
    // Handle retrieving favorites from a file or database
    res.json([]);
});

// Start server
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
}); 