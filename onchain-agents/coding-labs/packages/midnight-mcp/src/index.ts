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
 */

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { SSEServerTransport } from '@modelcontextprotocol/sdk/server/sse.js';
import { createServer } from 'http';
import { loadConfig } from './config.js';
import { registerTools } from './tools/index.js';
import { registerResources } from './resources/index.js';

const config = loadConfig();

const server = new McpServer({
  name: 'midnight-mcp',
  version: '0.1.0',
});

// Register all tools and resources
registerTools(server, config);
registerResources(server, config);

// --- HTTP server with SSE transport ---

// Track active transports for cleanup
const transports = new Map<string, SSEServerTransport>();

const httpServer = createServer(async (req, res) => {
  const url = new URL(req.url || '/', `http://${req.headers.host}`);

  // Health check
  if (url.pathname === '/health' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(
      JSON.stringify({ status: 'ok', server: 'midnight-mcp', version: '0.1.0' })
    );
    return;
  }

  // SSE endpoint - clients connect here for server-to-client messages
  if (url.pathname === '/sse' && req.method === 'GET') {
    const transport = new SSEServerTransport('/messages', res);
    transports.set(transport.sessionId, transport);

    res.on('close', () => {
      transports.delete(transport.sessionId);
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

    const transport = transports.get(sessionId);
    if (!transport) {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Session not found' }));
      return;
    }

    await transport.handlePostMessage(req, res);
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
