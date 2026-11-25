import express from 'express';
import { pool } from '../db/pool.js';
import { requireAuth } from '../middleware/auth.js';

const router = express.Router();
router.use(requireAuth);

const VALID_PERIODS = new Set(['daily', 'weekly', 'monthly', 'yearly']);
const VALID_GOAL_STATUSES = new Set(['completed', 'active', 'paused']);

function mapTx(r) {
  return {
    id: r.id,
    walletId: r.wallet_id,
    title: r.title,
    category: r.category,
    type: r.type,
    amount: Number(r.amount),
    paymentMethod: r.payment_method,
    verified: r.verified,
    occurredAt: r.occurred_at,
  };
}

function mapBudget(r) {
  return {
    id: r.id,
    name: r.name,
    category: r.category,
    period: r.period,
    limitAmount: Number(r.limit_amount),
    spentAmount: Number(r.spent_amount),
  };
}

function mapWallet(r) {
  const current = Number(r.current_amount);
  const target = Number(r.target_amount);
  return {
    id: r.id,
    name: r.name,
    icon: r.icon,
    colorVariant: r.color_variant,
    currentAmount: current,
    targetAmount: target,
    progressPercent: target > 0 ? Math.min(100, Math.round((current / target) * 100)) : 0,
  };
}

function mapGoal(r) {
  const saved = Number(r.saved_amount);
  const target = Number(r.target_amount);
  return {
    id: r.id,
    title: r.title,
    icon: r.icon,
    status: r.status,
    targetAmount: target,
    savedAmount: saved,
    progressPercent: target > 0 ? Math.min(100, Math.round((saved / target) * 100)) : 0,
  };
}

// GET /api/dashboard — Ringkasan lengkap untuk semua 6 layar MorFin
router.get('/dashboard', async (req, res) => {
  try {
    const uid = req.user.id;
    const [txRes, budRes, walRes, goalRes] = await Promise.all([
      pool.query('SELECT * FROM transactions WHERE user_id = $1 ORDER BY occurred_at DESC LIMIT 100', [uid]),
      pool.query('SELECT * FROM budgets WHERE user_id = $1 ORDER BY created_at ASC', [uid]),
      pool.query('SELECT * FROM wallets WHERE user_id = $1 ORDER BY created_at ASC', [uid]),
      pool.query('SELECT * FROM goals WHERE user_id = $1 ORDER BY created_at ASC', [uid]),
    ]);

    const txs = txRes.rows.map(mapTx);
    const budgets = budRes.rows.map(mapBudget);
    const wallets = walRes.rows.map(mapWallet);
    const goals = goalRes.rows.map(mapGoal);

    let totalIncome = 0;
    let totalExpense = 0;
    const catTotals = {};

    for (const tx of txs) {
      if (tx.type === 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        catTotals[tx.category] = (catTotals[tx.category] || 0) + tx.amount;
      }
    }

    const totalBalance = totalIncome - totalExpense;
    const savingsRate = totalIncome > 0 ? Math.max(0, Math.round(((totalIncome - totalExpense) / totalIncome) * 100)) : 0;

    // Weekly Mon..Sun under-budget streak strip
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const jsDay = new Date().getDay(); // 0=Sun..6=Sat
    const todayIdx = jsDay === 0 ? 6 : jsDay - 1;
    const weeklyDays = dayLabels.map((label, idx) => ({
      label,
      status: idx < todayIdx ? 'done' : idx === todayIdx ? 'today' : 'upcoming',
    }));

    // Category breakdown bars
    const defaultCats = ['Makan', 'Transport', 'Tagihan', 'Cloud AI', 'Edukasi', 'Hiburan', 'Tabungan'];
    const maxCat = Math.max(1, ...Object.values(catTotals), 500000);
    const categoryBars = defaultCats.map((name) => {
      const amount = catTotals[name] || (name === 'Tabungan' ? Math.max(0, totalBalance * 0.25) : 0);
      const pct = Math.min(100, Math.max(18, Math.round((amount / maxCat) * 100)));
      return {
        name,
        amount: Math.round(amount),
        percent: pct,
        healthy: name === 'Makan' || name === 'Tabungan' || pct <= 55,
      };
    });

    const goalCounts = {
      completed: goals.filter((g) => g.status === 'completed').length,
      active: goals.filter((g) => g.status === 'active').length,
      paused: goals.filter((g) => g.status === 'paused').length,
    };

    const monthlyBudgets = budgets.filter((b) => b.period === 'monthly');
    const monthlyLimit = monthlyBudgets.reduce((s, b) => s + b.limitAmount, 0);
    const monthlySpent = monthlyBudgets.reduce((s, b) => s + b.spentAmount, 0);
    const budgetRemaining = Math.max(0, monthlyLimit - monthlySpent);
    const budgetHealthPercent = monthlyLimit > 0 ? Math.max(0, Math.min(100, Math.round((budgetRemaining / monthlyLimit) * 100))) : 72;

    return res.json({
      summary: {
        totalBalance,
        totalIncome,
        totalExpense,
        savingsRate,
        hematStreakDays: 25,
        budgetRemaining,
        budgetHealthPercent,
        weeklyDays,
        categoryBars,
        goalCounts,
      },
      transactions: txs,
      budgets,
      wallets,
      goals,
    });
  } catch (err) {
    console.error('[dashboard]', err);
    return res.status(500).json({ error: 'Gagal memuat ringkasan keuangan.' });
  }
});

// ================= TRANSACTIONS CRUD =================
router.get('/transactions', async (req, res) => {
  const { type, category } = req.query;
  const params = [req.user.id];
  const where = ['user_id = $1'];
  if (type === 'income' || type === 'expense') {
    params.push(type);
    where.push(`type = $${params.length}`);
  }
  if (typeof category === 'string' && category.trim()) {
    params.push(category.trim());
    where.push(`category = $${params.length}`);
  }
  const r = await pool.query(
    `SELECT * FROM transactions WHERE ${where.join(' AND ')} ORDER BY occurred_at DESC LIMIT 200`,
    params
  );
  return res.json({ transactions: r.rows.map(mapTx) });
});

router.post('/transactions', async (req, res) => {
  try {
    const title = String(req.body?.title || '').trim();
    const category = String(req.body?.category || 'Lainnya').trim();
    const type = req.body?.type === 'income' ? 'income' : 'expense';
    const amount = Math.round(Number(req.body?.amount || 0));
    const paymentMethod = String(req.body?.paymentMethod || 'QRIS · E-Wallet').trim();
    const walletId = req.body?.walletId || null;

    if (!title) return res.status(400).json({ error: 'Keterangan transaksi wajib diisi.' });
    if (!Number.isFinite(amount) || amount <= 0) {
      return res.status(400).json({ error: 'Nominal harus lebih dari 0.' });
    }

    const r = await pool.query(
      `INSERT INTO transactions (user_id, wallet_id, title, category, type, amount, payment_method, verified)
       VALUES ($1, $2, $3, $4, $5, $6, $7, TRUE)
       RETURNING *`,
      [req.user.id, walletId, title, category, type, amount, paymentMethod]
    );

    if (type === 'expense') {
      await pool.query(
        `UPDATE budgets
         SET spent_amount = spent_amount + $1
         WHERE user_id = $2 AND category = $3`,
        [amount, req.user.id, category]
      );
    }

    return res.status(201).json({ transaction: mapTx(r.rows[0]) });
  } catch (err) {
    console.error('[create tx]', err);
    return res.status(500).json({ error: 'Gagal menyimpan transaksi.' });
  }
});

router.patch('/transactions/:id', async (req, res) => {
  const { verified, title, amount, category } = req.body || {};
  const r = await pool.query(
    `UPDATE transactions
     SET verified = COALESCE($1, verified),
         title = COALESCE($2, title),
         amount = COALESCE($3, amount),
         category = COALESCE($4, category)
     WHERE id = $5 AND user_id = $6
     RETURNING *`,
    [
      typeof verified === 'boolean' ? verified : null,
      typeof title === 'string' && title.trim() ? title.trim() : null,
      Number.isFinite(Number(amount)) && Number(amount) > 0 ? Math.round(Number(amount)) : null,
      typeof category === 'string' && category.trim() ? category.trim() : null,
      req.params.id,
      req.user.id,
    ]
  );
  if (r.rowCount === 0) return res.status(404).json({ error: 'Transaksi tidak ditemukan.' });
  return res.json({ transaction: mapTx(r.rows[0]) });
});

router.delete('/transactions/:id', async (req, res) => {
  const r = await pool.query(
    'DELETE FROM transactions WHERE id = $1 AND user_id = $2 RETURNING id',
    [req.params.id, req.user.id]
  );
  if (r.rowCount === 0) return res.status(404).json({ error: 'Transaksi tidak ditemukan.' });
  return res.json({ deleted: true, id: req.params.id });
});

// ================= BUDGETS CRUD =================
router.get('/budgets', async (req, res) => {
  const period = req.query.period;
  const params = [req.user.id];
  let sql = 'SELECT * FROM budgets WHERE user_id = $1';
  if (VALID_PERIODS.has(period)) {
    params.push(period);
    sql += ' AND period = $2';
  }
  sql += ' ORDER BY created_at ASC';
  const r = await pool.query(sql, params);
  return res.json({ budgets: r.rows.map(mapBudget) });
});

router.post('/budgets', async (req, res) => {
  const name = String(req.body?.name || '').trim();
  const category = String(req.body?.category || 'Makan').trim();
  const period = VALID_PERIODS.has(req.body?.period) ? req.body.period : 'monthly';
  const limitAmount = Math.round(Number(req.body?.limitAmount || 0));

  if (!name || limitAmount <= 0) {
    return res.status(400).json({ error: 'Nama anggaran dan batas nominal wajib diisi.' });
  }
  const r = await pool.query(
    `INSERT INTO budgets (user_id, name, category, period, limit_amount)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [req.user.id, name, category, period, limitAmount]
  );
  return res.status(201).json({ budget: mapBudget(r.rows[0]) });
});

router.delete('/budgets/:id', async (req, res) => {
  const r = await pool.query('DELETE FROM budgets WHERE id = $1 AND user_id = $2 RETURNING id', [
    req.params.id,
    req.user.id,
  ]);
  if (r.rowCount === 0) return res.status(404).json({ error: 'Anggaran tidak ditemukan.' });
  return res.json({ deleted: true });
});

// ================= WALLETS CRUD =================
router.get('/wallets', async (req, res) => {
  const r = await pool.query('SELECT * FROM wallets WHERE user_id = $1 ORDER BY created_at ASC', [req.user.id]);
  return res.json({ wallets: r.rows.map(mapWallet) });
});

router.post('/wallets', async (req, res) => {
  const name = String(req.body?.name || '').trim();
  const icon = String(req.body?.icon || 'shield').trim();
  const colorVariant = ['lime', 'dark', 'olive'].includes(req.body?.colorVariant) ? req.body.colorVariant : 'lime';
  const currentAmount = Math.max(0, Math.round(Number(req.body?.currentAmount || 0)));
  const targetAmount = Math.max(0, Math.round(Number(req.body?.targetAmount || 0)));
  if (!name) return res.status(400).json({ error: 'Nama kantong wajib diisi.' });

  const r = await pool.query(
    `INSERT INTO wallets (user_id, name, icon, color_variant, current_amount, target_amount)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [req.user.id, name, icon, colorVariant, currentAmount, targetAmount]
  );
  return res.status(201).json({ wallet: mapWallet(r.rows[0]) });
});

router.patch('/wallets/:id', async (req, res) => {
  const { currentAmount, targetAmount, name } = req.body || {};
  const r = await pool.query(
    `UPDATE wallets
     SET current_amount = COALESCE($1, current_amount),
         target_amount = COALESCE($2, target_amount),
         name = COALESCE($3, name)
     WHERE id = $4 AND user_id = $5
     RETURNING *`,
    [
      Number.isFinite(Number(currentAmount)) ? Math.max(0, Math.round(Number(currentAmount))) : null,
      Number.isFinite(Number(targetAmount)) ? Math.max(0, Math.round(Number(targetAmount))) : null,
      typeof name === 'string' && name.trim() ? name.trim() : null,
      req.params.id,
      req.user.id,
    ]
  );
  if (r.rowCount === 0) return res.status(404).json({ error: 'Kantong tidak ditemukan.' });
  return res.json({ wallet: mapWallet(r.rows[0]) });
});

// ================= GOALS CRUD =================
router.get('/goals', async (req, res) => {
  const r = await pool.query('SELECT * FROM goals WHERE user_id = $1 ORDER BY created_at ASC', [req.user.id]);
  return res.json({ goals: r.rows.map(mapGoal) });
});

router.post('/goals', async (req, res) => {
  const title = String(req.body?.title || '').trim();
  const icon = String(req.body?.icon || 'shield').trim();
  const status = VALID_GOAL_STATUSES.has(req.body?.status) ? req.body.status : 'active';
  const targetAmount = Math.max(0, Math.round(Number(req.body?.targetAmount || 0)));
  const savedAmount = Math.max(0, Math.round(Number(req.body?.savedAmount || 0)));
  if (!title) return res.status(400).json({ error: 'Nama target wajib diisi.' });

  const r = await pool.query(
    `INSERT INTO goals (user_id, title, icon, status, target_amount, saved_amount)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [req.user.id, title, icon, status, targetAmount, savedAmount]
  );
  return res.status(201).json({ goal: mapGoal(r.rows[0]) });
});

router.patch('/goals/:id', async (req, res) => {
  const { status, savedAmount, targetAmount, title } = req.body || {};
  const r = await pool.query(
    `UPDATE goals
     SET status = COALESCE($1, status),
         saved_amount = COALESCE($2, saved_amount),
         target_amount = COALESCE($3, target_amount),
         title = COALESCE($4, title)
     WHERE id = $5 AND user_id = $6
     RETURNING *`,
    [
      VALID_GOAL_STATUSES.has(status) ? status : null,
      Number.isFinite(Number(savedAmount)) ? Math.max(0, Math.round(Number(savedAmount))) : null,
      Number.isFinite(Number(targetAmount)) ? Math.max(0, Math.round(Number(targetAmount))) : null,
      typeof title === 'string' && title.trim() ? title.trim() : null,
      req.params.id,
      req.user.id,
    ]
  );
  if (r.rowCount === 0) return res.status(404).json({ error: 'Target tidak ditemukan.' });
  return res.json({ goal: mapGoal(r.rows[0]) });
});

router.delete('/goals/:id', async (req, res) => {
  const r = await pool.query('DELETE FROM goals WHERE id = $1 AND user_id = $2 RETURNING id', [
    req.params.id,
    req.user.id,
  ]);
  if (r.rowCount === 0) return res.status(404).json({ error: 'Target tidak ditemukan.' });
  return res.json({ deleted: true });
});

export default router;
