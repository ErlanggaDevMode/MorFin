import { pool } from './pool.js';

/**
 * Seeds sensible starter finance data for newly registered users so the
 * MorFin dashboard immediately feels alive and ready to customize.
 */
export async function seedStarterDataForUser(userId) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Starter Wallets (Kantong Tabungan)
    const w1 = await client.query(
      `INSERT INTO wallets (user_id, name, icon, color_variant, current_amount, target_amount)
       VALUES
         ($1, 'Dana Darurat', 'shield', 'lime', 19500000, 25000000),
         ($1, 'Gear & Workstation', 'laptop', 'dark', 14100000, 22000000),
         ($1, 'Reksadana & Saham', 'chart', 'olive', 13650000, 15000000)
       RETURNING id`,
      [userId]
    );
    const defaultWalletId = w1.rows[0]?.id ?? null;

    // 2. Starter Budgets across all 4 periods
    await client.query(
      `INSERT INTO budgets (user_id, name, category, period, limit_amount, spent_amount)
       VALUES
         ($1, 'Makan & Kopi Harian', 'Makan', 'daily', 75000, 38000),
         ($1, 'Transportasi & BBM', 'Transport', 'daily', 45000, 20000),
         ($1, 'Cloud, AI & Langganan', 'Cloud AI', 'daily', 30000, 10000),
         ($1, 'Kuliner & Belanja Mingguan', 'Makan', 'weekly', 525000, 305000),
         ($1, 'Komuter & Parkir', 'Transport', 'weekly', 315000, 128000),
         ($1, 'Hiburan & Nongkrong', 'Hiburan', 'weekly', 210000, 65000),
         ($1, 'Konsumsi & Kebutuhan Pokok', 'Makan', 'monthly', 1800000, 1150000),
         ($1, 'Tagihan, Listrik & Internet', 'Tagihan', 'monthly', 1200000, 960000),
         ($1, 'Alokasi Tabungan & Investasi', 'Tabungan', 'monthly', 1200000, 1100000),
         ($1, 'Dana Darurat Keluarga', 'Tabungan', 'yearly', 25000000, 19500000),
         ($1, 'Investasi Reksadana', 'Tabungan', 'yearly', 15000000, 13650000),
         ($1, 'Upgrade Produktivitas', 'Edukasi', 'yearly', 10000000, 6400000)`,
      [userId]
    );

    // 3. Starter Transactions (matching MorFin / KASU showcase)
    await client.query(
      `INSERT INTO transactions (user_id, wallet_id, title, category, type, amount, payment_method, verified, occurred_at)
       VALUES
         ($1, $2, 'Saldo Awal & Pemasukan Proyek', 'Gaji / Proyek', 'income', 11818000, 'Transfer · BCA', TRUE, NOW() - INTERVAL '2 days'),
         ($1, $2, 'Kopi Susu & Sarapan Pagi', 'Makan', 'expense', 38000, 'QRIS · E-Wallet', TRUE, NOW() - INTERVAL '6 hours'),
         ($1, $2, 'Pembayaran Termin Proyek Klien', 'Gaji / Proyek', 'income', 3500000, 'Transfer · BCA', TRUE, NOW() - INTERVAL '4 hours'),
         ($1, $2, 'Perpanjangan Cloud Server VPS & Domain', 'Cloud AI', 'expense', 245000, 'Kartu Debit', TRUE, NOW() - INTERVAL '2 hours'),
         ($1, $2, 'Belanja Kebutuhan Harian & Buah Segar', 'Tagihan', 'expense', 185000, 'QRIS · GoPay', FALSE, NOW() - INTERVAL '30 minutes')`,
      [userId, defaultWalletId]
    );

    // 4. Starter Financial Goals (6 Hexagonal Badges)
    await client.query(
      `INSERT INTO goals (user_id, title, icon, status, target_amount, saved_amount)
       VALUES
         ($1, 'Dana Darurat', 'shield', 'completed', 10000000, 10000000),
         ($1, 'Bebas Utang', 'coin', 'completed', 5000000, 5000000),
         ($1, 'Hemat Kopi', 'coffee', 'completed', 1000000, 1000000),
         ($1, 'Invest 10 Jt', 'chart', 'completed', 10000000, 10000000),
         ($1, 'Liburan Bali', 'plane', 'active', 8000000, 3200000),
         ($1, 'DP Rumah', 'home', 'paused', 80000000, 12000000)`,
      [userId]
    );

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
