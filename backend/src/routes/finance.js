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
  const limitAmount = Number(r.limit_amount);
  const spentAmount = Number(
    r.computed_spent_amount !== undefined ? r.computed_spent_amount : r.spent_amount
  );
  const usedPercent = limitAmount > 0 ? Math.round((spentAmount / limitAmount) * 100) : 0;
  const isOverBudget = limitAmount > 0 && spentAmount > limitAmount;
  const overAmount = isOverBudget ? spentAmount - limitAmount : 0;
  return {
    id: r.id,
    name: r.name,
    category: r.category,
    period: r.period,
    limitAmount,
    spentAmount,
    usedPercent,
    isOverBudget,
    overAmount,
  };
}

const BUDGET_WITH_PERIOD_SPENT_SQL = `
  SELECT
    b.*,
    COALESCE((
      SELECT SUM(t.amount)
      FROM transactions t
      WHERE t.user_id = b.user_id
        AND t.type = 'expense'
        AND LOWER(TRIM(t.category)) = LOWER(TRIM(b.category))
        AND t.occurred_at >= (
          CASE b.period
            WHEN 'daily'   THEN DATE_TRUNC('day',   NOW() AT TIME ZONE 'Asia/Jakarta')
            WHEN 'weekly'  THEN DATE_TRUNC('week',  NOW() AT TIME ZONE 'Asia/Jakarta')
            WHEN 'monthly' THEN DATE_TRUNC('month', NOW() AT TIME ZONE 'Asia/Jakarta')
            WHEN 'yearly'  THEN DATE_TRUNC('year',  NOW() AT TIME ZONE 'Asia/Jakarta')
            ELSE DATE_TRUNC('month', NOW() AT TIME ZONE 'Asia/Jakarta')
          END
        ) AT TIME ZONE 'Asia/Jakarta'
    ), 0) AS computed_spent_amount
  FROM budgets b
`;

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

// GET /api/dashboard — Ringkasan real-time untuk seluruh layar MorFin
router.get('/dashboard', async (req, res) => {
  try {
    const uid = req.user.id;
    const [txRes, budRes, walRes, goalRes] = await Promise.all([
      pool.query('SELECT * FROM transactions WHERE user_id = $1 ORDER BY occurred_at DESC LIMIT 200', [uid]),
      pool.query(`${BUDGET_WITH_PERIOD_SPENT_SQL} WHERE b.user_id = $1 ORDER BY b.created_at ASC`, [uid]),
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
    const savingsRate =
      totalIncome > 0 ? Math.max(0, Math.round(((totalIncome - totalExpense) / totalIncome) * 100)) : 0;

    // Weekly Mon..Sun under-budget check
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const jsDay = new Date().getDay();
    const todayIdx = jsDay === 0 ? 6 : jsDay - 1;
    const weeklyDays = dayLabels.map((label, idx) => ({
      label,
      status: idx < todayIdx ? 'done' : idx === todayIdx ? 'today' : 'upcoming',
    }));

    // Real 7-day (Sen..Min) weekly cashflow series for the vertical bar chart
    const indoDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const now = new Date();
    const startOfWeek = new Date(now);
    const diffToMon = now.getDay() === 0 ? 6 : now.getDay() - 1;
    startOfWeek.setHours(0, 0, 0, 0);
    startOfWeek.setDate(startOfWeek.getDate() - diffToMon);

    const weeklySeries = indoDays.map((label, idx) => {
      const d = new Date(startOfWeek);
      d.setDate(startOfWeek.getDate() + idx);
      const ymd = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      return {
        label,
        date: ymd,
        income: 0,
        expense: 0,
        isToday: idx === todayIdx,
      };
    });

    for (const tx of txs) {
      const td = new Date(tx.occurredAt);
      const ymd = `${td.getFullYear()}-${String(td.getMonth() + 1).padStart(2, '0')}-${String(td.getDate()).padStart(2, '0')}`;
      const bucket = weeklySeries.find((b) => b.date === ymd);
      if (bucket) {
        if (tx.type === 'income') bucket.income += tx.amount;
        else bucket.expense += tx.amount;
      }
    }

    // Also keep backward-compatible weeklyCashflowBars
    const maxTx = Math.max(1, ...txs.slice(0, 6).map((t) => t.amount));
    const weeklyCashflowBars =
      txs.length > 0
        ? txs.slice(0, 6).map((tx, idx) => {
            const widthFrac = Math.max(0.2, Math.min(0.84, (tx.amount / maxTx) * 0.78 + 0.14));
            const leftFrac = Math.min(1 - widthFrac - 0.02, ((idx * 13) % 34) / 100);
            return {
              label: tx.title,
              isIncome: tx.type === 'income',
              amount: tx.amount,
              leftFrac: Number(leftFrac.toFixed(2)),
              widthFrac: Number(widthFrac.toFixed(2)),
            };
          })
        : [];

    // Category breakdown bars
    const defaultCats = ['Makan', 'Transport', 'Tagihan', 'Cloud AI', 'Edukasi', 'Hiburan', 'Tabungan'];
    const maxCat = Math.max(1, ...Object.values(catTotals), 500000);
    const categoryBars = defaultCats.map((name) => {
      const amount = catTotals[name] || (name === 'Tabungan' ? Math.max(0, totalBalance * 0.2) : 0);
      const pct = amount > 0 ? Math.min(100, Math.max(16, Math.round((amount / maxCat) * 100))) : 10;
      return {
        name,
        amount: Math.round(amount),
        percent: pct,
        healthy: name === 'Tabungan' || pct <= 55,
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
    const budgetHealthPercent =
      monthlyLimit > 0 ? Math.max(0, Math.min(100, Math.round((budgetRemaining / monthlyLimit) * 100))) : 100;

    // Hitung streak "Hari Hemat Tanpa Boncos" secara nyata dari riwayat transaksi & batas anggaran
    const dailyBudgets = budgets.filter((b) => b.period === 'daily');
    const dailyLimitSum = dailyBudgets.reduce((s, b) => s + b.limitAmount, 0);
    const effectiveDailyLimit =
      dailyLimitSum > 0
        ? dailyLimitSum
        : monthlyLimit > 0
          ? Math.round(monthlyLimit / 30)
          : 0;

    let hematStreakDays = 0;
    if (txs.length > 0 && totalBalance >= 0) {
      const expenseByDay = new Map();
      let earliestTime = Date.now();
      for (const tx of txs) {
        const d = new Date(tx.occurredAt);
        if (!Number.isNaN(d.getTime())) {
          const dayStart = new Date(d.getFullYear(), d.getMonth(), d.getDate());
          if (dayStart.getTime() < earliestTime) earliestTime = dayStart.getTime();
          const key = `${dayStart.getFullYear()}-${String(dayStart.getMonth() + 1).padStart(2, '0')}-${String(dayStart.getDate()).padStart(2, '0')}`;
          if (tx.type === 'expense') {
            expenseByDay.set(key, (expenseByDay.get(key) || 0) + tx.amount);
          }
        }
      }

      const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const firstDayStart = new Date(earliestTime);
      const cursor = new Date(todayStart);

      while (cursor >= firstDayStart && hematStreakDays < 365) {
        const key = `${cursor.getFullYear()}-${String(cursor.getMonth() + 1).padStart(2, '0')}-${String(cursor.getDate()).padStart(2, '0')}`;
        const dayExp = expenseByDay.get(key) || 0;
        const isBoncos = effectiveDailyLimit > 0 && dayExp > effectiveDailyLimit;
        if (isBoncos) break;
        hematStreakDays += 1;
        cursor.setDate(cursor.getDate() - 1);
      }
    }

    return res.json({
      summary: {
        totalBalance,
        totalIncome,
        totalExpense,
        savingsRate,
        hematStreakDays,
        budgetRemaining,
        budgetHealthPercent,
        weeklyDays,
        weeklySeries,
        weeklyCashflowBars,
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

// POST /api/account/reset — Bersihkan data contoh & mulai pencatatan dari nol
router.post('/account/reset', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM transactions WHERE user_id = $1', [req.user.id]);
    await client.query('DELETE FROM budgets WHERE user_id = $1', [req.user.id]);
    await client.query('DELETE FROM wallets WHERE user_id = $1', [req.user.id]);
    await client.query('DELETE FROM goals WHERE user_id = $1', [req.user.id]);
    await client.query('COMMIT');
    return res.json({ reset: true });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[account reset]', err);
    return res.status(500).json({ error: 'Gagal mereset data akun.' });
  } finally {
    client.release();
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
    const occurredAt = req.body?.occurredAt ? new Date(req.body.occurredAt) : new Date();

    if (!title) return res.status(400).json({ error: 'Keterangan transaksi wajib diisi.' });
    if (!Number.isFinite(amount) || amount <= 0) {
      return res.status(400).json({ error: 'Nominal harus lebih dari 0.' });
    }

    const r = await pool.query(
      `INSERT INTO transactions (user_id, wallet_id, title, category, type, amount, payment_method, verified, occurred_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, TRUE, $8)
       RETURNING *`,
      [
        req.user.id,
        walletId,
        title,
        category,
        type,
        amount,
        paymentMethod,
        Number.isNaN(occurredAt.getTime()) ? new Date() : occurredAt,
      ]
    );

    if (walletId) {
      const delta = type === 'income' ? amount : -amount;
      await pool.query(
        `UPDATE wallets
         SET current_amount = GREATEST(0, current_amount + $1)
         WHERE id = $2 AND user_id = $3`,
        [delta, walletId, req.user.id]
      );
    }

    return res.status(201).json({ transaction: mapTx(r.rows[0]) });
  } catch (err) {
    console.error('[create tx]', err);
    return res.status(500).json({ error: 'Gagal menyimpan transaksi.' });
  }
});

router.patch('/transactions/:id', async (req, res) => {
  const { verified, title, amount, category, type, paymentMethod } = req.body || {};
  const r = await pool.query(
    `UPDATE transactions
     SET verified = COALESCE($1, verified),
         title = COALESCE($2, title),
         amount = COALESCE($3, amount),
         category = COALESCE($4, category),
         type = COALESCE($5, type),
         payment_method = COALESCE($6, payment_method)
     WHERE id = $7 AND user_id = $8
     RETURNING *`,
    [
      typeof verified === 'boolean' ? verified : null,
      typeof title === 'string' && title.trim() ? title.trim() : null,
      Number.isFinite(Number(amount)) && Number(amount) > 0 ? Math.round(Number(amount)) : null,
      typeof category === 'string' && category.trim() ? category.trim() : null,
      type === 'income' || type === 'expense' ? type : null,
      typeof paymentMethod === 'string' && paymentMethod.trim() ? paymentMethod.trim() : null,
      req.params.id,
      req.user.id,
    ]
  );
  if (r.rowCount === 0) return res.status(404).json({ error: 'Transaksi tidak ditemukan.' });
  return res.json({ transaction: mapTx(r.rows[0]) });
});

router.delete('/transactions/:id', async (req, res) => {
  const r = await pool.query(
    'DELETE FROM transactions WHERE id = $1 AND user_id = $2 RETURNING *',
    [req.params.id, req.user.id]
  );
  if (r.rowCount === 0) return res.status(404).json({ error: 'Transaksi tidak ditemukan.' });
  return res.json({ deleted: true, id: req.params.id });
});

// ================= BUDGETS CRUD =================
router.get('/budgets', async (req, res) => {
  const period = req.query.period;
  const params = [req.user.id];
  let sql = `${BUDGET_WITH_PERIOD_SPENT_SQL} WHERE b.user_id = $1`;
  if (VALID_PERIODS.has(period)) {
    params.push(period);
    sql += ' AND b.period = $2';
  }
  sql += ' ORDER BY b.created_at ASC';
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

router.patch('/budgets/:id', async (req, res) => {
  const { name, category, period, limitAmount, spentAmount } = req.body || {};
  const r = await pool.query(
    `UPDATE budgets
     SET name = COALESCE($1, name),
         category = COALESCE($2, category),
         period = COALESCE($3, period),
         limit_amount = COALESCE($4, limit_amount),
         spent_amount = COALESCE($5, spent_amount)
     WHERE id = $6 AND user_id = $7
     RETURNING *`,
    [
      typeof name === 'string' && name.trim() ? name.trim() : null,
      typeof category === 'string' && category.trim() ? category.trim() : null,
      VALID_PERIODS.has(period) ? period : null,
      Number.isFinite(Number(limitAmount)) && Number(limitAmount) > 0 ? Math.round(Number(limitAmount)) : null,
      Number.isFinite(Number(spentAmount)) && Number(spentAmount) >= 0 ? Math.round(Number(spentAmount)) : null,
      req.params.id,
      req.user.id,
    ]
  );
  if (r.rowCount === 0) return res.status(404).json({ error: 'Anggaran tidak ditemukan.' });
  return res.json({ budget: mapBudget(r.rows[0]) });
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

router.delete('/wallets/:id', async (req, res) => {
  const r = await pool.query('DELETE FROM wallets WHERE id = $1 AND user_id = $2 RETURNING id', [
    req.params.id,
    req.user.id,
  ]);
  if (r.rowCount === 0) return res.status(404).json({ error: 'Kantong tidak ditemukan.' });
  return res.json({ deleted: true });
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
