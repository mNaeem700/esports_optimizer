const { Pool } = require('pg');

let pool = null;
let usingMemoryFallback = false;

// In-memory fallback so the server is runnable immediately without a
// real Postgres instance (useful for local dev / demos). In production
// set DATABASE_URL and this branch is never used.
const memory = {
  users: [],
  relayServers: [
    { id: 1, server_name: 'US-East-1', region: 'us-east', country: 'US', latitude: 39.0, longitude: -77.5, ip_address: '203.0.113.10', capacity: 1000, current_load: 200, health_status: 'healthy' },
    { id: 2, server_name: 'EU-West-1', region: 'eu-west', country: 'IE', latitude: 53.3, longitude: -6.3, ip_address: '203.0.113.20', capacity: 1000, current_load: 150, health_status: 'healthy' },
    { id: 3, server_name: 'APAC-South-1', region: 'apac-south', country: 'SG', latitude: 1.35, longitude: 103.8, ip_address: '203.0.113.30', capacity: 1000, current_load: 400, health_status: 'healthy' },
    { id: 4, server_name: 'South-Asia-1', region: 'south-asia', country: 'PK', latitude: 31.5, longitude: 74.3, ip_address: '203.0.113.40', capacity: 500, current_load: 50, health_status: 'healthy' },
  ],
  metrics: [],
  subscriptions: [],
  nextUserId: 1,
};

function init() {
  if (process.env.DATABASE_URL) {
    pool = new Pool({ connectionString: process.env.DATABASE_URL });
    return pool;
  }
  usingMemoryFallback = true;
  console.warn('[db] DATABASE_URL not set — using in-memory store (dev/demo only, not persistent).');
  return null;
}

module.exports = { init, get pool() { return pool; }, get isMemory() { return usingMemoryFallback; }, memory };
