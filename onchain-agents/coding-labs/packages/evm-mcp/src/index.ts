/**
 * EVM MCP Server
 *
 * A shared MCP server exposing Foundry toolchain for EVM chains:
 *  - Forge (compile, deploy Solidity contracts)
 *  - Cast (call, send transactions)
 *  - Anvil (local fork for dev mode)
 *
 * Transport: SSE (Server-Sent Events) over HTTP
 * SDK: @modelcontextprotocol/sdk v1.x
 *
 * Session Constraints:
 *  - Only ONE EVM agent can use evm-mcp per session
 *  - Once a chain is selected, cannot switch mid-session
 *  - Anvil starts lazily when user specifies a chain
 */

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { SSEServerTransport } from '@modelcontextprotocol/sdk/server/sse.js';
import { createServer } from 'http';
import { loadConfig, type EvmMcpConfig, CHAIN_PRESETS } from './config.js';
import { registerTools } from './tools/index.js';
import { getSessionInfo, releaseSession } from './session.js';

const config = loadConfig();

/**
 * Create a new McpServer instance with all tools registered.
 * Each SSE connection gets its own server instance.
 */
function createMcpServer(cfg: EvmMcpConfig): McpServer {
  const server = new McpServer({
    name: 'evm-mcp',
    version: '0.1.0',
  });

  registerTools(server, cfg);

  return server;
}

// --- HTTP server with SSE transport ---

// Track active SSE connections: transport + server instance per connection
interface Connection {
  transport: SSEServerTransport;
  server: McpServer;
}
const connections = new Map<string, Connection>();

const httpServer = createServer(async (req, res) => {
  const url = new URL(req.url || '/', `http://${req.headers.host}`);

  // CORS headers for all responses
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Health check
  if (url.pathname === '/health' && req.method === 'GET') {
    const sessionInfo = getSessionInfo();
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(
      JSON.stringify({
        status: 'ok',
        server: 'evm-mcp',
        version: '0.1.0',
        activeConnections: connections.size,
        session: sessionInfo,
        config: {
          port: config.port,
          anvilPort: config.anvilPort,
          defaultSolcVersion: config.defaultSolcVersion,
        },
        availableChains: Object.keys(CHAIN_PRESETS),
      })
    );
    return;
  }

  // SSE endpoint - clients connect here for server-to-client messages
  if (url.pathname === '/sse' && req.method === 'GET') {
    // Create a new transport and server for this connection
    const transport = new SSEServerTransport('/messages', res);
    const server = createMcpServer(config);

    const connectionId = transport.sessionId;
    connections.set(connectionId, { transport, server });

    console.log(
      `[evm-mcp] New SSE connection: ${connectionId} (active: ${connections.size})`
    );

    res.on('close', async () => {
      console.log(`[evm-mcp] SSE connection closed: ${connectionId}`);
      connections.delete(connectionId);

      // If this was the connection that held the session, release it
      const sessionInfo = getSessionInfo();
      if (
        sessionInfo.hasActiveSession &&
        sessionInfo.sessionId === connectionId
      ) {
        releaseSession(connectionId);
      }
    });

    await server.connect(transport);
    return;
  }

  // Messages endpoint - clients POST messages here
  if (url.pathname === '/messages' && req.method === 'POST') {
    const sessionId = url.searchParams.get('sessionId');
    if (!sessionId) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Missing sessionId parameter' }));
      return;
    }

    const connection = connections.get(sessionId);
    if (!connection) {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Connection not found' }));
      return;
    }

    await connection.transport.handlePostMessage(req, res);
    return;
  }

  // 404 for everything else
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(
    JSON.stringify({
      error: 'Not found',
      endpoints: {
        health: 'GET /health',
        sse: 'GET /sse',
        messages: 'POST /messages?sessionId=<id>',
      },
    })
  );
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('[evm-mcp] Received SIGTERM, shutting down...');
  releaseSession(); // Release any active session (stops Anvil)
  httpServer.close(() => {
    console.log('[evm-mcp] Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('[evm-mcp] Received SIGINT, shutting down...');
  releaseSession();
  httpServer.close(() => {
    console.log('[evm-mcp] Server closed');
    process.exit(0);
  });
});

httpServer.listen(config.port, config.host, () => {
  console.log(
    `EVM MCP server listening on http://${config.host}:${config.port}`
  );
  console.log(`  SSE endpoint:         GET  /sse`);
  console.log(`  Messages:             POST /messages?sessionId=<id>`);
  console.log(`  Health:               GET  /health`);
  console.log(`  Anvil port:           ${config.anvilPort}`);
  console.log(`  Default Solc version: ${config.defaultSolcVersion}`);
  console.log(
    `  Available chains:     ${Object.keys(CHAIN_PRESETS).join(', ')}`
  );
});
