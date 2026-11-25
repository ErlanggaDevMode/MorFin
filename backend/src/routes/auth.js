import express from 'express';
import bcrypt from 'bcryptjs';
import { OAuth2Client } from 'google-auth-library';
import { pool } from '../db/pool.js';
import { seedStarterDataForUser } from '../db/seedUser.js';
import { requireAuth, signAccessToken } from '../middleware/auth.js';

const router = express.Router();
const googleClient = new OAuth2Client();

function sanitizeUser(row) {
  return {
    id: row.id,
    email: row.email,
    name: row.name,
    avatarUrl: row.avatar_url,
    authProvider: row.auth_provider,
    hideBalance: row.hide_balance,
    currency: row.currency,
    createdAt: row.created_at,
  };
}

function getAllowedGoogleAudiences() {
  return (process.env.GOOGLE_CLIENT_IDS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

async function verifyGoogleCredentials({ idToken, accessToken }) {
  const audiences = getAllowedGoogleAudiences();

  if (idToken) {
    const verifyOpts = { idToken };
    if (audiences.length > 0) verifyOpts.audience = audiences;
    const ticket = await googleClient.verifyIdToken(verifyOpts);
    const payload = ticket.getPayload();
    if (!payload || !payload.email || !payload.sub) {
      throw new Error('Payload Google ID Token tidak lengkap.');
    }
    return {
      sub: payload.sub,
      email: payload.email.toLowerCase(),
      name: payload.name || payload.email.split('@')[0],
      avatarUrl: payload.picture || null,
    };
  }

  if (accessToken) {
    const resp = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!resp.ok) {
      throw new Error('Google Access Token tidak valid.');
    }
    const info = await resp.json();
    if (!info.email || !info.sub) {
      throw new Error('Profil Google tidak lengkap.');
    }
    return {
      sub: info.sub,
      email: info.email.toLowerCase(),
      name: info.name || info.email.split('@')[0],
      avatarUrl: info.picture || null,
    };
  }

  throw new Error('idToken atau accessToken Google wajib disertakan.');
}

// POST /api/auth/register — Daftar Akun Baru via Email & Password
router.post('/register', async (req, res) => {
  try {
    const email = String(req.body?.email || '').trim().toLowerCase();
    const password = String(req.body?.password || '');
    const name = String(req.body?.name || '').trim();
    const seedDemo = req.body?.seedDemo !== false;

    if (!email || !email.includes('@')) {
      return res.status(400).json({ error: 'Format email tidak valid.' });
    }
    if (!name || name.length < 2) {
      return res.status(400).json({ error: 'Nama minimal 2 karakter.' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password minimal 6 karakter.' });
    }

    const exists = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (exists.rowCount > 0) {
      return res.status(409).json({ error: 'Email sudah terdaftar. Silakan masuk.' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const inserted = await pool.query(
      `INSERT INTO users (email, name, password_hash, auth_provider)
       VALUES ($1, $2, $3, 'email')
       RETURNING *`,
      [email, name, passwordHash]
    );

    const userRow = inserted.rows[0];
    if (seedDemo) {
      await seedStarterDataForUser(userRow.id);
    }

    const token = signAccessToken(userRow);
    return res.status(201).json({
      token,
      user: sanitizeUser(userRow),
    });
  } catch (err) {
    console.error('[register]', err);
    return res.status(500).json({ error: 'Gagal mendaftarkan akun baru.' });
  }
});

// POST /api/auth/login — Masuk via Email & Password
router.post('/login', async (req, res) => {
  try {
    const email = String(req.body?.email || '').trim().toLowerCase();
    const password = String(req.body?.password || '');

    if (!email || !password) {
      return res.status(400).json({ error: 'Email dan password wajib diisi.' });
    }

    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rowCount === 0) {
      return res.status(401).json({ error: 'Email atau password salah.' });
    }

    const userRow = result.rows[0];
    if (!userRow.password_hash) {
      return res.status(401).json({
        error: 'Akun ini terdaftar lewat Google. Silakan masuk menggunakan Akun Google.',
      });
    }

    const ok = await bcrypt.compare(password, userRow.password_hash);
    if (!ok) {
      return res.status(401).json({ error: 'Email atau password salah.' });
    }

    const token = signAccessToken(userRow);
    return res.json({
      token,
      user: sanitizeUser(userRow),
    });
  } catch (err) {
    console.error('[login]', err);
    return res.status(500).json({ error: 'Gagal memproses login.' });
  }
});

// POST /api/auth/google — OAuth 2.0 Google Sign-In / Auto-Register
router.post('/google', async (req, res) => {
  try {
    const { idToken, accessToken } = req.body || {};
    if (!idToken && !accessToken) {
      return res.status(400).json({ error: 'Google idToken atau accessToken wajib diisi.' });
    }

    let profile;
    try {
      profile = await verifyGoogleCredentials({ idToken, accessToken });
    } catch (verifyErr) {
      return res.status(401).json({ error: `Verifikasi Google gagal: ${verifyErr.message}` });
    }

    let userRow;
    const existing = await pool.query(
      'SELECT * FROM users WHERE google_sub = $1 OR email = $2 LIMIT 1',
      [profile.sub, profile.email]
    );

    if (existing.rowCount > 0) {
      const prev = existing.rows[0];
      const nextProvider = prev.password_hash ? 'both' : 'google';
      const updated = await pool.query(
        `UPDATE users
         SET google_sub = COALESCE(google_sub, $1),
             avatar_url = COALESCE($2, avatar_url),
             auth_provider = $3,
             updated_at = NOW()
         WHERE id = $4
         RETURNING *`,
        [profile.sub, profile.avatarUrl, nextProvider, prev.id]
      );
      userRow = updated.rows[0];
    } else {
      const inserted = await pool.query(
        `INSERT INTO users (email, name, google_sub, avatar_url, auth_provider)
         VALUES ($1, $2, $3, $4, 'google')
         RETURNING *`,
        [profile.email, profile.name, profile.sub, profile.avatarUrl]
      );
      userRow = inserted.rows[0];
      await seedStarterDataForUser(userRow.id);
    }

    const token = signAccessToken(userRow);
    return res.json({
      token,
      user: sanitizeUser(userRow),
    });
  } catch (err) {
    console.error('[google auth]', err);
    return res.status(500).json({ error: 'Gagal masuk dengan Akun Google.' });
  }
});

// GET /api/auth/me
router.get('/me', requireAuth, async (req, res) => {
  const r = await pool.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
  if (r.rowCount === 0) return res.status(404).json({ error: 'Pengguna tidak ditemukan.' });
  return res.json({ user: sanitizeUser(r.rows[0]) });
});

// PATCH /api/auth/preferences
router.patch('/preferences', requireAuth, async (req, res) => {
  const { hideBalance, name } = req.body || {};
  const r = await pool.query(
    `UPDATE users
     SET hide_balance = COALESCE($1, hide_balance),
         name = COALESCE($2, name),
         updated_at = NOW()
     WHERE id = $3
     RETURNING *`,
    [
      typeof hideBalance === 'boolean' ? hideBalance : null,
      typeof name === 'string' && name.trim().length >= 2 ? name.trim() : null,
      req.user.id,
    ]
  );
  if (r.rowCount === 0) return res.status(404).json({ error: 'Pengguna tidak ditemukan.' });
  return res.json({ user: sanitizeUser(r.rows[0]) });
});

export default router;
