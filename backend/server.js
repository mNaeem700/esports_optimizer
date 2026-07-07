require('dotenv').config();
const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');

const db = require('./db/pool');
const { authenticateToken } = require('./services/auth');
const { selectBestRelay } = require('./services/routingEngine');
const authRoutes = require('./routes/auth');
const apiRoutes = require('./routes/api');

db.init();

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok', mode: db.isMemory ? 'memory' : 'postgres' }));

app.use('/api/auth', authRoutes);
app.use('/api', authenticateToken, apiRoutes);

// --- WebSocket: real-time network metrics & ping/pong RTT ---
io.on('connection', (socket) => {
  console.log(`[ws] client connected: ${socket.id}`);
  const clientState = { lastSeen: Date.now() };

  socket.on('client-connected', (data) => {
    clientState.deviceId = data?.deviceId;
    clientState.location = data?.location; // { lat, lon }
    console.log(`[ws] ${socket.id} identified as device ${clientState.deviceId}`);
  });

  socket.on('ping', (data) => {
    socket.emit('pong', { timestamp: Date.now(), originalTimestamp: data?.timestamp });
  });

  socket.on('request-relay', (data) => {
    const relays = db.isMemory ? db.memory.relayServers : [];
    const loc = data?.location || clientState.location;
    if (!loc) {
      socket.emit('relay-error', { error: 'location required' });
      return;
    }
    const best = selectBestRelay(loc, relays, data?.measuredLatencies || {});
    socket.emit('relay-selected', best);
  });

  socket.on('network-metrics', (metrics) => {
    // In production: write to TimescaleDB hypertable (see db/schema.sql)
    if (db.isMemory) {
      db.memory.metrics.push({ ts: Date.now(), socketId: socket.id, ...metrics });
      if (db.memory.metrics.length > 5000) db.memory.metrics.shift();
    }
  });

  socket.on('disconnect', () => {
    console.log(`[ws] client disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Esports Optimizer backend listening on port ${PORT} (${db.isMemory ? 'in-memory mode' : 'postgres mode'})`);
});

module.exports = { app, server, io };
