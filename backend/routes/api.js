const express = require('express');
const db = require('../db/pool');
const { selectBestRelay } = require('../services/routingEngine');

const router = express.Router();

// --- User profile ---
router.get('/user/profile', async (req, res) => {
  const userId = req.user.id;
  if (db.isMemory) {
    const user = db.memory.users.find((u) => u.id === userId);
    if (!user) return res.status(404).json({ error: 'not found' });
    return res.json({ id: user.id, email: user.email });
  }
  const result = await db.pool.query('SELECT id, email, created_at FROM users WHERE id = $1', [userId]);
  if (!result.rows.length) return res.status(404).json({ error: 'not found' });
  res.json(result.rows[0]);
});

// --- Subscriptions ---
router.get('/subscription/status', async (req, res) => {
  const userId = req.user.id;
  if (db.isMemory) {
    const sub = db.memory.subscriptions.find((s) => s.user_id === userId) || { plan_type: 'free', status: 'active' };
    return res.json(sub);
  }
  const result = await db.pool.query(
    'SELECT plan_type, status, expires_at FROM subscriptions WHERE user_id = $1 ORDER BY started_at DESC LIMIT 1',
    [userId]
  );
  res.json(result.rows[0] || { plan_type: 'free', status: 'active' });
});

router.post('/subscription/start-trial', async (req, res) => {
  const userId = req.user.id;
  const expires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  if (db.isMemory) {
    db.memory.subscriptions.push({ user_id: userId, plan_type: 'premium', status: 'active', expires_at: expires });
    return res.status(201).json({ plan_type: 'premium', status: 'active', expires_at: expires });
  }
  const result = await db.pool.query(
    `INSERT INTO subscriptions (user_id, plan_type, expires_at) VALUES ($1, 'premium', $2)
     RETURNING plan_type, status, expires_at`,
    [userId, expires]
  );
  res.status(201).json(result.rows[0]);
});

// NOTE: real payment capture (Stripe) is intentionally NOT wired to fake
// success here — see README "Payments" section for what's required.
router.post('/subscription/upgrade-premium', (req, res) => {
  res.status(501).json({
    error: 'Not implemented in this scaffold. Wire this to a real Stripe secret key + webhook handler before going live — see README.',
  });
});

// --- Relay network ---
router.get('/relays', async (req, res) => {
  if (db.isMemory) return res.json(db.memory.relayServers);
  const result = await db.pool.query('SELECT * FROM relay_servers');
  res.json(result.rows);
});

router.post('/relays/select', async (req, res) => {
  const { latitude, longitude, measuredLatencies } = req.body;
  if (typeof latitude !== 'number' || typeof longitude !== 'number') {
    return res.status(400).json({ error: 'latitude and longitude (numbers) are required' });
  }

  const relays = db.isMemory ? db.memory.relayServers : (await db.pool.query('SELECT * FROM relay_servers')).rows;
  const best = selectBestRelay({ lat: latitude, lon: longitude }, relays, measuredLatencies || {});
  if (!best) return res.status(503).json({ error: 'no healthy relays available' });
  res.json(best);
});

module.exports = router;
