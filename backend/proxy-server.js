// Simple HTTP proxy to forward network requests to localhost
const http = require('http');
const httpProxy = require('http-proxy-middleware');
const express = require('express');

const proxyApp = express();
const PROXY_PORT = 3001;
const TARGET_PORT = 3000;

// Create proxy middleware
const apiProxy = httpProxy.createProxyMiddleware({
  target: `http://localhost:${TARGET_PORT}`,
  changeOrigin: true,
  secure: false,
  logLevel: 'info'
});

// Use the proxy for all requests
proxyApp.use('/', apiProxy);

// Start the proxy server
const proxyServer = proxyApp.listen(PROXY_PORT, '0.0.0.0', () => {
  console.log(`🔗 Proxy server running on port ${PROXY_PORT}`);
  console.log(`📱 Mobile access: http://192.168.1.154:${PROXY_PORT}/api`);
  console.log(`🌐 Network access: http://192.168.1.154:${PROXY_PORT}/health`);
  console.log(`➡️ Forwarding to: http://localhost:${TARGET_PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Proxy server shutting down...');
  proxyServer.close();
});
