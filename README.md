# RoastLine

Aplikasi manajemen deadline yang "nge-roast" kamu kalau nunda tugas.
Tugas mata kuliah **Pemrograman Aplikasi & Perangkat Bergerak**.

**Tech stack:** Flutter · Supabase (database + auth) · Firebase Cloud Messaging (notifikasi) · Provider (state management)

## Fitur 

Register · Login · Reset kata sandi · Lihat profil · Lihat daftar tugas ·
Tambah tugas · Lihat detail tugas (countdown + roast) · Tandai tugas selesai ·
Hapus tugas · Notifikasi.

## Mulai

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=<project-url> \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Langkah lengkap (skema database, konfigurasi Supabase & Firebase, pemetaan
use case ke kode) ada di **[SETUP.md](SETUP.md)**.
Skema database: **[supabase/schema.sql](supabase/schema.sql)**.
