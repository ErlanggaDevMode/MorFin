import test from 'node:test';
import assert from 'node:assert/strict';
import 'dotenv/config';

const BASE = process.env.TEST_BASE_URL || 'http://127.0.0.1:4200';

test('MorFin API end-to-end auth + PostgreSQL finance CRUD', async () => {
  // 1. Health check
  const health = await fetch(`${BASE}/health`).then((r) => r.json());
  assert.equal(health.status, 'ok');
  assert.equal(health.db, 'postgresql');

  // 2. Register brand-new user via Email
  const email = `morfin_test_${Date.now()}@nayakacode.web.id`;
  const regRes = await fetch(`${BASE}/api/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: 'Test MorFin', email, password: 'Password123!' }),
  });
  assert.equal(regRes.status, 201);
  const regData = await regRes.json();
  assert.ok(regData.token);
  assert.equal(regData.user.email, email);

  // 3. Login via Email
  const loginRes = await fetch(`${BASE}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: 'Password123!' }),
  });
  assert.equal(loginRes.status, 200);
  const { token } = await loginRes.json();
  const authHeaders = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`,
  };

  // 4. Google OAuth endpoint rejects missing/fake token cleanly (400/401)
  const gBad = await fetch(`${BASE}/api/auth/google`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ idToken: 'invalid-token' }),
  });
  assert.equal(gBad.status, 401);

  // 5. Dashboard starts completely clean & empty by default for new users
  const dash = await fetch(`${BASE}/api/dashboard`, { headers: authHeaders }).then((r) => r.json());
  assert.equal(dash.summary.totalBalance, 0);
  assert.equal(dash.summary.hematStreakDays, 0);
  assert.equal(dash.transactions.length, 0);
  assert.equal(dash.wallets.length, 0);
  assert.equal(dash.budgets.length, 0);
  assert.equal(dash.goals.length, 0);

  // 6. Create & toggle & delete Transaction
  const txCreate = await fetch(`${BASE}/api/transactions`, {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify({
      title: 'Makan Siang Soto',
      category: 'Makan',
      type: 'expense',
      amount: 28000,
      paymentMethod: 'QRIS',
    }),
  });
  assert.equal(txCreate.status, 201);
  const { transaction } = await txCreate.json();
  assert.equal(transaction.amount, 28000);

  const txPatch = await fetch(`${BASE}/api/transactions/${transaction.id}`, {
    method: 'PATCH',
    headers: authHeaders,
    body: JSON.stringify({ verified: false }),
  });
  assert.equal(txPatch.status, 200);
  assert.equal((await txPatch.json()).transaction.verified, false);

  const txDel = await fetch(`${BASE}/api/transactions/${transaction.id}`, {
    method: 'DELETE',
    headers: authHeaders,
  });
  assert.equal(txDel.status, 200);

  // 7. Create & toggle Goal
  const goalCreate = await fetch(`${BASE}/api/goals`, {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify({ title: 'Beli Sepeda', icon: 'chart', targetAmount: 4500000, savedAmount: 1000000 }),
  });
  assert.equal(goalCreate.status, 201);
  const { goal } = await goalCreate.json();

  const goalPatch = await fetch(`${BASE}/api/goals/${goal.id}`, {
    method: 'PATCH',
    headers: authHeaders,
    body: JSON.stringify({ status: 'completed', savedAmount: 4500000 }),
  });
  assert.equal(goalPatch.status, 200);
  assert.equal((await goalPatch.json()).goal.status, 'completed');

  // 8. Daily budget ignores yesterday's expenses and computes uncapped % (e.g. 200%) for today
  const budCreate = await fetch(`${BASE}/api/budgets`, {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify({ name: 'Jajan Harian', category: 'Makan', period: 'daily', limitAmount: 25000 }),
  });
  assert.equal(budCreate.status, 201);

  const yesterdayIso = new Date(Date.now() - 26 * 60 * 60 * 1000).toISOString();
  const txYest = await fetch(`${BASE}/api/transactions`, {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify({
      title: 'Kopi Kemarin',
      category: 'Makan',
      type: 'expense',
      amount: 50000,
      paymentMethod: 'QRIS',
      occurredAt: yesterdayIso,
    }),
  });
  assert.equal(txYest.status, 201);

  const dashAfterYest = await fetch(`${BASE}/api/dashboard`, { headers: authHeaders }).then((r) => r.json());
  assert.equal(dashAfterYest.budgets[0].spentAmount, 0);
  assert.equal(dashAfterYest.budgets[0].usedPercent, 0);

  const txToday = await fetch(`${BASE}/api/transactions`, {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify({
      title: 'Kopi Hari Ini',
      category: 'Makan',
      type: 'expense',
      amount: 50000,
      paymentMethod: 'QRIS',
    }),
  });
  assert.equal(txToday.status, 201);

  const dashAfterToday = await fetch(`${BASE}/api/dashboard`, { headers: authHeaders }).then((r) => r.json());
  assert.equal(dashAfterToday.budgets[0].spentAmount, 50000);
  assert.equal(dashAfterToday.budgets[0].usedPercent, 200);
  assert.equal(dashAfterToday.budgets[0].isOverBudget, true);
  assert.equal(dashAfterToday.budgets[0].overAmount, 25000);
});
