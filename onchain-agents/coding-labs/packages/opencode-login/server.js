/**
 * dCoder Login Page Server
 *
 * Simple Express static file server for the login landing page.
 * Serves files from the public/ directory.
 */

import express from 'express';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 8080;
const APP_URL = process.env.APP_URL || 'http://localhost:4097';

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'opencode-login' });
});

// Serve APP_URL as a JSON endpoint for the frontend
app.get('/config', (req, res) => {
  res.json({ appUrl: APP_URL });
});

// Serve static files from public directory
app.use(express.static(join(__dirname, 'public')));

// Fallback to index.html for SPA-like behavior
app.get('*', (req, res) => {
  res.sendFile(join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`[opencode-login] Server running on http://0.0.0.0:${PORT}`);
  console.log(`[opencode-login] APP_URL configured as: ${APP_URL}`);
});
