/**
 * Midnight MCP Server
 *
 * A combined MCP server exposing Midnight Network infrastructure:
 *  - Compact compiler (compile, validate)
 *  - Proof Server (ZK proof generation)
 *  - Indexer (contract state, block queries)
 *  - Faucet (testnet token requests)
 *
 * Transport: SSE (Server-Sent Events) over HTTP
 * SDK: @modelcontextprotocol/sdk v1.x
 *
 * IMPORTANT: Each SSE connection gets its own McpServer instance.
 * The MCP SDK's McpServer can only be connected to one transport at a time,
 * so we create a fresh instance for each client connection.
 */

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { SSEServerTransport } from '@modelcontextprotocol/sdk/server/sse.js';
import { createServer } from 'http';
import { loadConfig, type MidnightMCPConfig } from './config.js';
import { registerTools } from './tools/index.js';
import { registerResources } from './resources/index.js';

const config = loadConfig();

/**
 * Create a new McpServer instance with all tools and resources registered.
 * Each SSE connection gets its own server instance.
 */
function createMcpServer(cfg: MidnightMCPConfig): McpServer {
  const server = new McpServer({
    name: 'midnight-mcp',
    version: '0.1.0',
  });

  registerTools(server, cfg);
  registerResources(server, cfg);

  return server;
}

// --- HTTP server with SSE transport ---

// Track active sessions: transport + server instance per connection
interface Session {
  transport: SSEServerTransport;
  server: McpServer;
}
const sessions = new Map<string, Session>();

const httpServer = createServer(async (req, res) => {
  const url = new URL(req.url || '/', `http://${req.headers.host}`);

  // Health check
  if (url.pathname === '/health' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(
      JSON.stringify({
        status: 'ok',
        server: 'midnight-mcp',
        version: '0.1.0',
        activeSessions: sessions.size,
      })
    );
    return;
  }

  // SSE endpoint - clients connect here for server-to-client messages
  if (url.pathname === '/sse' && req.method === 'GET') {
    // Create a new transport and server for this connection
    const transport = new SSEServerTransport('/messages', res);
    const server = createMcpServer(config);

    const sessionId = transport.sessionId;
    sessions.set(sessionId, { transport, server });

    console.log(
      `[midnight-mcp] New SSE connection: ${sessionId} (active: ${sessions.size})`
    );

    res.on('close', async () => {
      console.log(`[midnight-mcp] SSE connection closed: ${sessionId}`);
      sessions.delete(sessionId);
      // Server cleanup happens automatically when transport closes
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

    const session = sessions.get(sessionId);
    if (!session) {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Session not found' }));
      return;
    }

    await session.transport.handlePostMessage(req, res);
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

httpServer.listen(config.port, config.host, () => {
  console.log(
    `Midnight MCP server listening on http://${config.host}:${config.port}`
  );
  console.log(`  SSE endpoint:     GET  /sse`);
  console.log(`  Messages:         POST /messages?sessionId=<id>`);
  console.log(`  Health:           GET  /health`);
  console.log(`  Default network:  ${config.defaultNetwork}`);
  console.log(`  Compact binary:   ${config.compactBinaryPath}`);
});
