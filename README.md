# MorFin — Neo-Flat Personal Finance Tracker (Flutter + PostgreSQL VPS)

Aplikasi pencatat keuangan pribadi **MorFin** dengan desain **Neo-Flat Matcha Lime (`#A5CB53`) + Carbon (`#181A18`) + Pistachio (`#F2F8E9`)**, terhubung langsung ke backend REST API & database **PostgreSQL 17** yang berjalan di VPS, lengkap dengan autentikasi **Email + Password (Daftar & Masuk)** serta **OAuth 2.0 Akun Google**.

- **Live Flutter Web Preview**: https://nayakacode.web.id/morfin/
- **Live Production API**: https://nayakacode.web.id/morfin-api/health
- **Referensi Desain UI**: https://nayakacode.web.id/kasu/

---

## Fitur Utama

### 1. Autentikasi & Keamanan
- **Daftar Akun Baru & Masuk (Email + Password)** dengan hashing `bcryptjs` dan token sesi **JWT**.
- **OAuth 2.0 Akun Google (`google_sign_in 7.x`)** dengan verifikasi kriptografis ID Token / Access Token di backend (`google-auth-library`) + auto-registrasi / penautan akun otomatis.
- **Mode Privasi Saldo** (`hideBalance`) tersinkronisasi per pengguna di PostgreSQL.

### 2. UI/UX Neo-Flat 6 Alur Utama
1. **Splash Screen (`MorFin`)**: Ilustrasi geometris flat *half-circle* + tombol `Let's Start`.
2. **Beranda (Dashboard)**:
   - Kartu saldo gelap dengan **notch toggle privasi** & strip kepatuhan budget `Mon–Sun`.
   - Bento **Anggaran** (`% Terkendali`) + **Hari Hemat Tanpa Boncos** (ikon api flat).
   - Grafik **Arus Kas Mingguan** (pemasukan vs pengeluaran).
3. **Anggaran (`Harian / Mingguan / Bulanan / Tahunan`)**: 4 periode bulat, hero card piala *Keep It Up!*, kartu budget selang-seling, dan modal tambah anggaran baru.
4. **Transaksi Harian (Timeline)**: Timeline transaksi `+Rp`/`-Rp`, tombol centang verifikasi, geser untuk hapus (*swipe-to-delete*), dan modal catat transaksi baru.
5. **Kategori & Kantong Tabungan**: Bar chart pengeluaran per kategori + *bottom dark sheet* berisi **kartu kantong tabungan bertumpuk interaktif** (ketuk untuk angkat kartu, `+ Top Up` saldo tabungan).
6. **Target Keuangan (Dark Mode)**: 3 blok statistik lime + tombol notch `↗` + grid **lencana heksagonal** milestone finansial yang bisa diubah statusnya (`Tercapai`, `Berjalan`, `Tertunda`) + tambah target baru.

---

## Struktur Monorepo

```text
MorFin/
├── backend/                 # Node.js + Express + PostgreSQL 17 REST API
│   ├── src/
│   │   ├── db/              # pool.js, schema.sql (auto-migrate), seedUser.js
│   │   ├── middleware/      # JWT requireAuth middleware
│   │   ├── routes/          # auth.js (Email + Google OAuth), finance.js (CRUD)
│   │   └── server.js        # Entry point API (default port 4200)
│   ├── test/api.test.js     # Integration test end-to-end PostgreSQL
│   └── .env.example
└── mobile/                  # Aplikasi Flutter (Android, iOS, Web)
    ├── lib/
    │   ├── core/            # AppConfig, MorfinTheme, formatIdr
    │   ├── models/          # Model User, Transaction, Budget, Wallet, Goal
    │   ├── services/        # MorfinApi HTTP client
    │   ├── state/           # MorfinController (ChangeNotifier + JWT storage)
    │   ├── widgets/         # NeoFlatArt CustomPainter, HexagonBadge, AddSheets
    │   └── screens/         # Splash, Auth, Home, Budget, Transactions, Goals
    └── test/widget_test.dart
```

---

## Menjalankan Secara Lokal

### 1. Backend API (VPS / Lokal)
```bash
cd backend
cp .env.example .env
# Isi DATABASE_URL PostgreSQL, JWT_SECRET, dan GOOGLE_CLIENT_IDS
npm install
npm start
# Jalankan integration test:
npm test
```

### 2. Aplikasi Flutter (Android / iOS / Web)
```bash
cd mobile
flutter pub get
flutter analyze
flutter test

# Jalankan terhubung ke VPS produksi (default: https://nayakacode.web.id/morfin-api):
flutter run

# Atau dengan Google OAuth Client ID Anda:
flutter run \
  --dart-define=GOOGLE_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

### Konfigurasi Google OAuth (Opsional untuk Produksi Google Sign-In)
1. Buat OAuth 2.0 Client ID (Android SHA-1, iOS Bundle ID, dan Web Client ID) di **Google Cloud Console**.
2. Masukkan daftar Client ID ke `GOOGLE_CLIENT_IDS` di `backend/.env` lalu restart `systemctl restart morfin-api`.
3. Pass `--dart-define=GOOGLE_CLIENT_ID=...` dan `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` saat build Flutter.

---

Dibangun bersama **Nayakacode**.
