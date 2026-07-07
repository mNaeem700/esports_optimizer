const express = require('express');
const bcrypt = require('bcryptjs');
const { signToken } = require('../services/auth');
const db = require('../db/pool');

const router = express.Router();

router.post('/register', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'email and password are required' });
  if (password.length < 8) return res.status(400).json({ error: 'password must be at least 8 characters' });

  if (db.isMemory) {
    const exists = db.memory.users.find((u) => u.email === email);
    if (exists) return res.status(409).json({ error: 'user already exists' });
    const password_hash = await bcrypt.hash(password, 10);
    const user = { id: db.memory.nextUserId++, email, password_hash };
    db.memory.users.push(user);
    return res.status(201).json({ token: signToken(user), user: { id: user.id, email: user.email } });
  }

  try {
    const existing = await db.pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length) return res.status(409).json({ error: 'user already exists' });
    const password_hash = await bcrypt.hash(password, 10);
    const result = await db.pool.query(
      'INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id, email',
      [email, password_hash]
    );
    const user = result.rows[0];
    res.status(201).json({ token: signToken(user), user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'registration failed' });
  }
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'email and password are required' });

  let user;
  if (db.isMemory) {
    user = db.memory.users.find((u) => u.email === email);
  } else {
    const result = await db.pool.query('SELECT * FROM users WHERE email = $1', [email]);
    user = result.rows[0];
  }

  if (!user) return res.status(401).json({ error: 'invalid credentials' });
  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) return res.status(401).json({ error: 'invalid credentials' });

  res.json({ token: signToken(user), user: { id: user.id, email: user.email } });
});

module.exports = router;
