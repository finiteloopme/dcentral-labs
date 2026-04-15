/**
 * ADK Backend - Startup Script
 *
 * Starts the ADK web server which serves both:
 * - The ADK REST API (sessions, run, run_sse, list-apps)
 * - The adk-web Angular frontend (dev UI)
 *
 * The agent definition is in agents/playground/agent.ts and is
 * auto-discovered by the ADK CLI.
 *
 * Usage:
 *   npx adk web ./agents --port 8181 --a2a
 *
 * This file exists for TypeScript compilation validation only.
 * The actual startup is handled by the `adk web` CLI command
 * via the package.json scripts.
 */

console.log('[adk-backend] Starting ADK web server...');
console.log('[adk-backend] Agent definitions: ./agents');
console.log(`[adk-backend] Port: ${process.env.PORT || 8181}`);
console.log(`[adk-backend] Environment: ${process.env.NODE_ENV || 'development'}`);

// The ADK CLI handles the actual server startup.
// This file is a placeholder for the TypeScript build step.
// In production, the Containerfile runs `npx adk web` directly.
