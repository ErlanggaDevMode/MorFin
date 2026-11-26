import express from 'express';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { pool } from '../db/pool.js';
import { requireAuth } from '../middleware/auth.js';

const execFileAsync = promisify(execFile);
const router = express.Router();
router.use(requireAuth);

const INCOME_KEYWORDS = [
  'gaji', 'terima', 'dapat', 'dapet', 'masuk', 'bonus', 'freelance',
  'bayaran', 'honor', 'komisi', 'dividen', 'refund', 'cashback',
  'jualan', 'omset', 'omzet', 'profit', 'transfer masuk', 'uang saku',
  'kiriman', 'thr', 'pemasukan', 'pendapatan', 'dibayar', 'invoice',
];

const CATEGORY_RULES = [
  {
    category: 'Makan',
    words: [
      'makan', 'minum', 'kopi', 'coffee', 'cafe', 'kafe', 'warteg', 'nasi',
      'bakso', 'mie', 'ayam', 'soto', 'sate', 'jajan', 'snack', 'roti',
      'boba', 'teh', 'es', 'sarapan', 'lunch', 'dinner', 'gofood', 'grabfood',
      'shopeefood', 'resto', 'restoran', 'warung', 'mcd', 'kfc', 'starbucks',
      'fore', 'kenangan', 'janji jiwa', 'mixue', 'chatime', 'indomaret', 'alfamart',
      'alfamidi', 'supermarket', 'hypermart', 'minuman', 'makanan', 'gorengan',
    ],
  },
  {
    category: 'Transport',
    words: [
      'bensin', 'pertamax', 'pertalite', 'solar', 'spbu', 'shell', 'parkir',
      'tol', 'gojek', 'grab', 'goride', 'gocar', 'grabcar', 'maxim', 'indrive',
      'ojol', 'ojek', 'taxi', 'taksi', 'kereta', 'krl', 'mrt', 'lrt', 'bus',
      'transjakarta', 'tiket', 'pesawat', 'servis', 'bengkel', 'oli', 'cuci motor',
      'cuci mobil', 'transport',
    ],
  },
  {
    category: 'Tagihan',
    words: [
      'listrik', 'pln', 'token', 'air', 'pdam', 'wifi', 'internet', 'indihome',
      'biznet', 'pulsa', 'paket data', 'kuota', 'telkomsel', 'xl', 'indosat',
      'byu', 'kos', 'kost', 'kontrakan', 'sewa', 'cicilan', 'tagihan', 'bpjs',
      'asuransi', 'pajak', 'iuran', 'netflix', 'spotify', 'youtube', 'icloud',
    ],
  },
  {
    category: 'Cloud AI',
    words: [
      'chatgpt', 'openai', 'claude', 'gemini', 'vps', 'server', 'domain',
      'hosting', 'cloud', 'github', 'copilot', 'cursor', 'midjourney', 'api',
      'digitalocean', 'aws', 'gcp', 'vercel', 'supabase', 'figma',
    ],
  },
  {
    category: 'Edukasi',
    words: [
      'buku', 'kursus', 'kelas', 'kuliah', 'spp', 'ukt', 'les', 'seminar',
      'workshop', 'udemy', 'coursera', 'alat tulis', 'fotokopi', 'print',
      'kertas', 'kampus', 'skripsi', 'edukasi',
    ],
  },
  {
    category: 'Hiburan',
    words: [
      'bioskop', 'nonton', 'xxi', 'cgv', 'game', 'steam', 'topup', 'top up',
      'konser', 'karaoke', 'liburan', 'wisata', 'hotel', 'staycation', 'billiard',
      'hiburan', 'bowling', 'gym', 'olahraga', 'futsal', 'badminton',
    ],
  },
  {
    category: 'Tabungan',
    words: ['tabung', 'nabung', 'tabungan', 'investasi', 'reksadana', 'saham', 'emas', 'bibit', 'dana darurat'],
  },
];

function detectPaymentMethod(textLower) {
  if (/\b(qris|gopay|ovo|dana|shopeepay|spay|linkaja|e-?wallet)\b/i.test(textLower)) {
    return 'QRIS · E-Wallet';
  }
  if (/\b(transfer|bca|mandiri|bri|bni|bsi|jago|seabank|blu|debit|atm|m-?banking|va|virtual account)\b/i.test(textLower)) {
    return 'Transfer Bank';
  }
  if (/\b(kartu kredit|credit card|cc|visa|mastercard|paylater)\b/i.test(textLower)) {
    return 'Kartu Kredit';
  }
  if (/\b(cash|tunai|uang pas|kontan)\b/i.test(textLower)) {
    return 'Tunai / Cash';
  }
  return 'QRIS · E-Wallet';
}

function detectCategory(textLower, type) {
  if (type === 'income') return 'Pemasukan';
  for (const rule of CATEGORY_RULES) {
    for (const w of rule.words) {
      if (textLower.includes(w)) return rule.category;
    }
  }
  return 'Lainnya';
}

function parseAmountToken(numStr, unitStr) {
  const unit = (unitStr || '').toLowerCase().trim();
  let clean = numStr.trim();

  if (unit === 'jt' || unit === 'juta') {
    clean = clean.replace(',', '.');
    const val = parseFloat(clean);
    return Number.isFinite(val) ? Math.round(val * 1_000_000) : 0;
  }
  if (unit === 'rb' || unit === 'ribu' || unit === 'k') {
    clean = clean.replace(',', '.');
    const val = parseFloat(clean);
    return Number.isFinite(val) ? Math.round(val * 1_000) : 0;
  }

  // Standard Rupiah formats like 50.000, 1.250.000, 50,000, 50000, 50.000,00
  clean = clean.replace(/[,.]00$/, '');
  const digitsOnly = clean.replace(/[^0-9]/g, '');
  const val = parseInt(digitsOnly, 10);
  return Number.isFinite(val) ? val : 0;
}

function titleCase(str) {
  return str
    .replace(/\s+/g, ' ')
    .trim()
    .split(' ')
    .filter(Boolean)
    .map((w) => (w.length <= 2 && /^[a-z]+$/i.test(w) ? w.toLowerCase() : w[0].toUpperCase() + w.slice(1)))
    .join(' ');
}

function parseSingleSegment(segment) {
  const raw = segment.trim();
  if (!raw) return null;
  const lower = raw.toLowerCase();

  // Match amounts: "Rp 50.000", "28rb", "5,5jt", "35k", "50 ribu", "250000"
  const amtRegex = /(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+|\d+(?:[.,]\d{1,2})?)\s*(juta|jt|ribu|rb|k)?\b/gi;
  let bestMatch = null;
  let bestAmount = 0;

  for (const m of raw.matchAll(amtRegex)) {
    const val = parseAmountToken(m[1], m[2]);
    // Ignore tiny standalone numbers like "2" (quantity) unless suffixed with rb/jt/k or >= 500
    const hasUnit = Boolean(m[2]) || /^rp/i.test(m[0]);
    if ((hasUnit && val >= 100) || (!hasUnit && val >= 500 && val <= 10_000_000_000)) {
      if (val > bestAmount) {
        bestAmount = val;
        bestMatch = m;
      }
    }
  }

  if (!bestMatch || bestAmount <= 0) return null;

  const isIncome = INCOME_KEYWORDS.some((kw) => lower.includes(kw));
  const type = isIncome ? 'income' : 'expense';
  const category = detectCategory(lower, type);
  const paymentMethod = detectPaymentMethod(lower);

  // Determine occurredAt ("kemarin" -> yesterday)
  let occurredAt = new Date();
  if (/\bkemarin\b/i.test(lower)) {
    occurredAt = new Date(Date.now() - 24 * 60 * 60 * 1000);
  }

  // Clean title by stripping the matched amount, filler verbs, payment keywords, and time words
  let title = raw
    .replace(bestMatch[0], ' ')
    .replace(/\b(beli|bayar|buat|untuk|habis|keluar|pengeluaran|pemasukan|catat|catet|tolong|pakai|pake|via|lewat|dengan|sebesar|senilai|harga|kemarin|hari ini|tadi|qris|gopay|ovo|dana|shopeepay|cash|tunai|transfer|bank|bca|mandiri|bri|bni|debit)\b/gi, ' ')
    .replace(/[^\p{L}\p{N}\s&/-]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  if (!title || title.length < 2) {
    title = isIncome ? 'Pemasukan' : category;
  } else {
    title = titleCase(title).slice(0, 60);
  }

  return {
    title,
    category,
    type,
    amount: bestAmount,
    paymentMethod,
    occurredAt: occurredAt.toISOString(),
  };
}

export function parseNaturalFinanceText(text) {
  const cleaned = String(text || '').trim();
  if (!cleaned) return [];

  // Split by newlines, semicolons, or ", " / " dan " only when multiple amounts exist
  const roughParts = cleaned
    .split(/\n|;|(?:\s+dan\s+)|(?:,\s+(?=[a-zA-Z]))/i)
    .map((s) => s.trim())
    .filter(Boolean);

  const parsed = [];
  for (const part of roughParts) {
    const item = parseSingleSegment(part);
    if (item) parsed.push(item);
  }

  if (parsed.length === 0) {
    const fallback = parseSingleSegment(cleaned);
    if (fallback) parsed.push(fallback);
  }
  return parsed;
}

function parseReceiptOcrText(ocrText) {
  const lines = String(ocrText || '')
    .split(/\r?\n/)
    .map((l) => l.replace(/\s+/g, ' ').trim())
    .filter((l) => l.length >= 2);

  const fullLower = lines.join('\n').toLowerCase();

  // 1. Detect merchant from top lines (skip purely numeric, address/phone, or date lines)
  let merchant = '';
  for (const line of lines.slice(0, 6)) {
    const clean = line.replace(/[^A-Za-z0-9\s&'.-]/g, '').trim();
    if (
      clean.length >= 3 &&
      !/^(jl\.?|jalan|telp|phone|npwp|struk|nota|receipt|tgl|date|\d{2}[/-]\d{2})/i.test(clean) &&
      /[A-Za-z]{3,}/.test(clean)
    ) {
      merchant = titleCase(clean).slice(0, 48);
      break;
    }
  }

  // 2. Detect grand total prioritizing explicit TOTAL lines
  const priorityPatterns = [
    /(?:grand\s*total|total\s*bayar|total\s*belanja|total\s*tagihan|total\s*pembayaran|net\s*total|total\s*due|jumlah\s*bayar)/i,
    /\btotal\b/i,
    /\b(?:sub\s*total|subtotal|bayar|tunai|qris|debit|amount|jumlah)\b/i,
  ];

  const extractLineMoney = (line) => {
    const matches = [...line.matchAll(/(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+|\d{4,9})(?:[,.]\d{2})?\b/gi)];
    let best = 0;
    for (const m of matches) {
      const val = parseAmountToken(m[1], '');
      if (val >= 500 && val <= 500_000_000 && val > best) {
        best = val;
      }
    }
    return best;
  };

  let totalAmount = 0;
  for (const regex of priorityPatterns) {
    for (let i = lines.length - 1; i >= 0; i--) {
      if (regex.test(lines[i]) && !/kembali|change|kembalian|poin|point|hemat|diskon|disc/i.test(lines[i])) {
        const val = extractLineMoney(lines[i]);
        if (val > 0) {
          totalAmount = val;
          break;
        }
        // Sometimes total value is on the very next line
        if (i + 1 < lines.length) {
          const nextVal = extractLineMoney(lines[i + 1]);
          if (nextVal > 0) {
            totalAmount = nextVal;
            break;
          }
        }
      }
    }
    if (totalAmount > 0) break;
  }

  // Fallback: largest plausible Rp value across the receipt (ignoring phone/receipt IDs >= 500M)
  if (totalAmount === 0) {
    for (const line of lines) {
      if (/telp|hp|wa|npwp|id|no\.|trx|ref|kembali|change/i.test(line)) continue;
      const val = extractLineMoney(line);
      if (val >= 1000 && val <= 50_000_000 && val > totalAmount) {
        totalAmount = val;
      }
    }
  }

  // 3. Detect date on receipt if available (DD/MM/YYYY or DD-MM-YY or YYYY-MM-DD)
  let occurredAt = new Date();
  const dmy = fullLower.match(/\b(\d{1,2})[/-](\d{1,2})[/-](20\d{2}|\d{2})\b/);
  if (dmy) {
    const day = parseInt(dmy[1], 10);
    const mon = parseInt(dmy[2], 10);
    let yr = parseInt(dmy[3], 10);
    if (yr < 100) yr += 2000;
    if (mon >= 1 && mon <= 12 && day >= 1 && day <= 31 && yr >= 2020 && yr <= 2035) {
      const parsedDate = new Date(yr, mon - 1, day, 12, 0, 0);
      if (!Number.isNaN(parsedDate.getTime())) occurredAt = parsedDate;
    }
  }

  const category = detectCategory(fullLower, 'expense');
  const paymentMethod = detectPaymentMethod(fullLower);
  const title = merchant ? `Belanja ${merchant}` : 'Struk Belanja';

  return {
    title,
    category,
    type: 'expense',
    amount: totalAmount,
    paymentMethod,
    occurredAt: occurredAt.toISOString(),
  };
}

// POST /api/chat/parse — Parse natural Indonesian text / voice transcript into draft transaction(s)
router.post('/parse', async (req, res) => {
  try {
    const text = String(req.body?.text || '').trim();
    if (!text) {
      return res.status(400).json({ error: 'Pesan tidak boleh kosong.' });
    }

    const items = parseNaturalFinanceText(text);
    if (items.length > 0) {
      const summary =
        items.length === 1
          ? `Siap! Aku tangkap ${items[0].type === 'income' ? 'pemasukan' : 'pengeluaran'} "${items[0].title}" sebesar Rp ${items[0].amount.toLocaleString('id-ID')}. Cek detailnya di bawah lalu ketuk Simpan ya!`
          : `Mantap! Aku menemukan ${items.length} catatan transaksi sekaligus. Kamu bisa simpan langsung satu per satu di bawah ini.`;
      return res.json({ reply: summary, items });
    }

    // Conversational quick finance lookup if user asks about balance / spending
    const lower = text.toLowerCase();
    if (/(saldo|uang|sisa|total|laporan|pengeluaran|pemasukan|ringkasan)/i.test(lower)) {
      const txRes = await pool.query(
        'SELECT type, amount FROM transactions WHERE user_id = $1',
        [req.user.id]
      );
      let inc = 0;
      let exp = 0;
      for (const r of txRes.rows) {
        if (r.type === 'income') inc += Number(r.amount);
        else exp += Number(r.amount);
      }
      const bal = inc - exp;
      return res.json({
        reply: `Ringkasan akunmu saat ini:\n• Saldo Bersih: Rp ${bal.toLocaleString('id-ID')}\n• Total Pemasukan: Rp ${inc.toLocaleString('id-ID')}\n• Total Pengeluaran: Rp ${exp.toLocaleString('id-ID')}\n\nUntuk mencatat cepat, cukup ketik contoh: "Beli kopi 25rb qris" atau tekan tombol mic / foto struk!`,
        items: [],
      });
    }

    return res.json({
      reply:
        'Aku belum menemukan nominal transaksi di pesan itu. Coba sebutkan nominalnya ya, misalnya:\n• "Beli kopi kenangan 28rb qris"\n• "Makan siang 35k cash"\n• "Gaji masuk 5jt transfer"\n\nAtau gunakan tombol Rekam Suara / Scan Struk di bawah!',
      items: [],
    });
  } catch (err) {
    console.error('[chat parse]', err);
    return res.status(500).json({ error: 'Gagal memproses pesan chat.' });
  }
});

// POST /api/chat/scan-receipt — OCR Indonesian receipt / nota belanja via Pillow + Tesseract
router.post('/scan-receipt', async (req, res) => {
  const tmpId = crypto.randomBytes(8).toString('hex');
  const rawPath = path.join(os.tmpdir(), `morfin_receipt_${tmpId}.img`);
  const prepPath = path.join(os.tmpdir(), `morfin_receipt_${tmpId}.png`);

  try {
    const rawB64 = String(req.body?.imageBase64 || '').trim();
    if (!rawB64) {
      return res.status(400).json({ error: 'Gambar struk tidak ditemukan.' });
    }

    const stripped = rawB64.includes(',') ? rawB64.split(',').pop() : rawB64;
    const buffer = Buffer.from(stripped, 'base64');
    if (buffer.length < 200) {
      return res.status(400).json({ error: 'File gambar terlalu kecil atau rusak.' });
    }
    if (buffer.length > 9 * 1024 * 1024) {
      return res.status(413).json({ error: 'Ukuran foto struk maksimal 9 MB.' });
    }

    await fs.writeFile(rawPath, buffer);

    // Preprocess image with Pillow (EXIF auto-orient, grayscale, autocontrast, upscale if small)
    const pyScript = `
import sys
from PIL import Image, ImageOps, ImageEnhance
im = Image.open(sys.argv[1])
im = ImageOps.exif_transpose(im).convert('L')
w, h = im.size
if max(w, h) < 1200:
    scale = 1200 / max(w, h)
    im = im.resize((int(w * scale), int(h * scale)), Image.LANCZOS)
elif max(w, h) > 2200:
    scale = 2200 / max(w, h)
    im = im.resize((int(w * scale), int(h * scale)), Image.LANCZOS)
im = ImageOps.autocontrast(im, cutoff=1)
im = ImageEnhance.Sharpness(im).enhance(1.6)
im.save(sys.argv[2], 'PNG')
`;
    await execFileAsync('python3', ['-c', pyScript, rawPath, prepPath], { timeout: 15000 });

    const { stdout } = await execFileAsync(
      'tesseract',
      [prepPath, 'stdout', '-l', 'ind+eng', '--psm', '6'],
      { timeout: 25000, maxBuffer: 2 * 1024 * 1024 }
    );

    const ocrText = (stdout || '').trim();
    const parsed = parseReceiptOcrText(ocrText);

    if (parsed.amount > 0) {
      return res.json({
        reply: `Struk berhasil dipindai! Terbaca "${parsed.title}" dengan total Rp ${parsed.amount.toLocaleString('id-ID')} (${parsed.category} · ${parsed.paymentMethod}). Kamu bisa langsung Simpan atau Edit kalau ada yang perlu disesuaikan.`,
        rawText: ocrText.slice(0, 1200),
        items: [parsed],
      });
    }

    return res.json({
      reply:
        'Foto struk sudah terbaca, tapi total nominalnya belum terdeteksi otomatis. Coba foto lebih terang/dekat, atau ketik nominalnya di chat ya (misal: "Belanja Indomaret 45rb").',
      rawText: ocrText.slice(0, 1200),
      items: [],
    });
  } catch (err) {
    console.error('[scan-receipt]', err);
    return res.status(500).json({ error: 'Gagal memindai struk belanja. Pastikan file berupa foto JPG/PNG yang jelas.' });
  } finally {
    await fs.rm(rawPath, { force: true }).catch(() => {});
    await fs.rm(prepPath, { force: true }).catch(() => {});
  }
});

export default router;
