import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { pool, runMigrations } from './db/pool.js';
import authRoutes from './routes/auth.js';
import financeRoutes from './routes/finance.js';

const app = express();
const PORT = Number(process.env.PORT || 4200);

app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(
  cors({
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);
app.use(express.json({ limit: '1mb' }));

app.get('/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    return res.json({ status: 'ok', service: 'morfin-api', db: 'postgresql' });
  } catch (err) {
    return res.status(503).json({ status: 'error', error: err.message });
  }
});

app.use('/api/auth', authRoutes);
app.use('/api', financeRoutes);

app.use((_req, res) => {
  res.status(404).json({ error: 'Endpoint tidak ditemukan.' });
});

export async function startServer() {
  await runMigrations();
  return app.listen(PORT, '127.0.0.1', () => {
    console.log(`[morfin-api] Listening on http://127.0.0.1:${PORT}`);
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  startServer().catch((err) => {
    console.error('[morfin-api] Fatal startup error:', err);
    process.exit(1);
  });
}

export default app;
