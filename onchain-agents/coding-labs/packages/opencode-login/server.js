/**
 * dCoder Login Page Server
 *
 * Express server hosting the magic-link sign-in UI under the LB + IAP + GCIP
 * agent-flow architecture (issue #60).
 *
 * Routes:
 *   GET /health         — liveness probe
 *   GET /config         — public Firebase config + APP_URL for the SPA
 *   GET /login          — sign-in page (renders public/index.html)
 *   GET /__/auth/handler — magic-link return handler (static file)
 *   GET /*              — fallback to public/index.html
 *
 * Firebase env vars are PUBLIC (browser-safe):
 *   - FIREBASE_API_KEY      — Identity Toolkit web API key
 *   - FIREBASE_AUTH_DOMAIN  — typically <project>.firebaseapp.com
 *   - FIREBASE_PROJECT_ID   — GCP project hosting GCIP
 */

import express from 'express';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 8080;
const APP_URL = process.env.APP_URL || 'http://localhost:4097';
const FIREBASE_API_KEY = process.env.FIREBASE_API_KEY || '';
const FIREBASE_AUTH_DOMAIN = process.env.FIREBASE_AUTH_DOMAIN || '';
const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID || '';

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'opencode-login' });
});

// Public Firebase config + app URL for the browser SPA
app.get('/config', (req, res) => {
  res.json({
    appUrl: APP_URL,
    firebase: {
      apiKey: FIREBASE_API_KEY,
      authDomain: FIREBASE_AUTH_DOMAIN,
      projectId: FIREBASE_PROJECT_ID,
    },
  });
});

// Explicit /login route — serves the same SPA as `/`. Declared BEFORE the
// static middleware so it always resolves to index.html regardless of how the
// LB URL map normalizes trailing slashes.
app.get('/login', (req, res) => {
  res.sendFile(join(__dirname, 'public', 'index.html'));
});

// Serve static files from public/ (includes /__/auth/handler.html and
// /styles.css). Express resolves /__/auth/handler.html naturally.
app.use(express.static(join(__dirname, 'public')));

// Fallback to index.html for SPA-like behavior on unknown paths
app.get('*', (req, res) => {
  res.sendFile(join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`[opencode-login] Server running on http://0.0.0.0:${PORT}`);
  console.log(`[opencode-login] APP_URL configured as: ${APP_URL}`);
  console.log(
    `[opencode-login] Firebase configured: ${
      FIREBASE_API_KEY ? 'yes' : 'NO (sign-in will fail)'
    }`
  );
});
