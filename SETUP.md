# Julidline — Panduan Setup

Aplikasi manajemen deadline (Flutter + Supabase + Firebase Cloud Messaging)
untuk tugas **Pemrograman Aplikasi & Perangkat Bergerak**.

## Ringkasan Arsitektur

```
lib/
├─ main.dart                     # entry point, init Supabase + FCM, daftar Provider
├─ app.dart                      # MaterialApp + AuthGate (login vs home)
├─ core/
│  ├─ config/supabase_config.dart   # URL & anon key (via --dart-define)
│  ├─ constants/app_colors.dart
│  ├─ theme/app_theme.dart
│  └─ utils/                        # date_formatter, roast_generator
├─ data/
│  ├─ models/                       # Profile, Task, AppNotification  
│  ├─ services/                     # supabase_service, fcm_service
│  └─ repositories/                 # auth, profile, task, notification
├─ controllers/                     # ChangeNotifier (Provider): auth, task, profile, notification
└─ views/
   ├─ auth/                         # login, register, forgot_password + AuthHeader
   ├─ home/                         # shell: bottom nav (Utama / Jadwal) + FAB tengah
   ├─ dashboard/                    # layar "Utama": sapaan, RoastBot harian, week strip, tugas terdekat
   ├─ task_list/                    # "Jadwal" / "Lihat Semua": tugas dikelompokkan per waktu + TaskCard
   ├─ add_task/                     # form tambah tugas
   ├─ task_detail/                  # countdown live + roast Brutal Mode + selesai/hapus
   ├─ profile/                      # profil (di-push dari avatar) + dialog logout
   └─ notifications/                # daftar notifikasi (tabel notifications)
```

Navigasi: avatar di dashboard → `ProfilePage`. Tombol **+** → `AddTaskPage`.
Tab **Jadwal** & tombol **Lihat Semua** → `TaskListPage`.

### Pemetaan Use Case → Kode

| Use Case (diagram)      | File utama                                   |
|-------------------------|----------------------------------------------|
| Register                | `views/auth/register_page.dart` → `AuthRepository.register` |
| Login                   | `views/auth/login_page.dart` → `AuthRepository.login` |
| Mereset Kata Sandi      | `views/auth/forgot_password_page.dart` → `AuthRepository.resetPassword` |
| Melihat Profil Pengguna | `views/profile/profile_page.dart` → `ProfileRepository.getProfile` |
| Melihat Daftar Tugas    | `views/dashboard/dashboard_page.dart` + `views/task_list/task_list_page.dart` → `TaskRepository.getTasks` |
| Menambah Tugas Baru     | `views/add_task/add_task_page.dart` → `TaskRepository.addTask` |
| Melihat Detail Tugas    | `views/task_detail/task_detail_page.dart` → `TaskRepository.getTask` |
| Menandai Tugas Selesai  | `TaskRepository.setCompleted` (isi `completed_at`) |
| Menghapus Tugas         | `TaskRepository.deleteTask` |

Fitur tambahan (di luar use case inti):

| Fitur | File |
|---|---|
| Edit Tugas | `AddTaskPage(task: ...)` → `TaskController.updateTask` (dari tombol ✏️ di detail) |
| Edit Nama Profil | `ProfilePage._editName` → `ProfileController.updateName` |
| Ganti Password | `ProfilePage._changePassword` → `AuthController.changePassword` |
| Kartu statistik (Aktif/Telat/Selesai) | `DashboardPage` → `_StatCell` |
| Kalender bisa diklik per tanggal | `WeekStrip` → `DashboardPage._selectedDay` |

---

## 1. Setup Supabase

1. Buat project di <https://supabase.com>.
2. Buka **SQL Editor**, jalankan seluruh isi [`supabase/schema.sql`](supabase/schema.sql).
   Ini membuat tabel `profiles`, `tasks`, `notifications` (sesuai ERD),
   trigger auto-create profil, dan Row Level Security.
3. Buka **Project Settings → API**, salin:
   - `Project URL`
   - `anon` / `public` key
4. (Opsional) **Authentication → Sign In / Providers → Email**: matikan
   "Confirm email" saat development supaya bisa langsung login setelah register.
5. **Authentication → URL Configuration → Redirect URLs**: tambahkan
   `io.supabase.roastline://login-callback/`
   (wajib untuk flow reset password lewat deep link — lihat bagian 4).

Kredensial dibaca dari **`assets/env.json`** (otomatis saat app start) atau
lewat `--dart-define`. Salin `assets/env.example.json` → `assets/env.json`,
isi kedua nilainya. Kalau belum diisi, muncul layar pengingat (tidak crash).

---

## 2. Notifikasi

Julidline punya **3 lapis notifikasi**, semua sudah aktif kecuali FCM (butuh
project Firebase).

| Lapis | Butuh | Status |
|---|---|---|
| **Feed dalam app** (tabel `notifications`) | Supabase saja | ✅ aktif |
| **Reminder lokal terjadwal** (`flutter_local_notifications`) | Android/iOS device | ✅ aktif |
| **Push FCM** | project Firebase | ⚙️ perlu `flutterfire configure` |

### Alur (lihat "Bagaimana notifikasi bekerja" di bawah)

- **Tambah tugas** → baris feed `task_added` + reminder lokal dijadwalkan ke OS
  pada H‑24 jam, H‑6 jam, H‑1 jam, **tepat deadline (`due`)**, dan **~1 menit
  setelah deadline (`overdue`)** — untuk ambang yang masih di masa depan.
- Saat ambang lewat: OS memunculkan notifikasi roast (walau app tertutup),
  DAN entri yang sama masuk ke feed halaman **Notifikasi**.
- **Ticker foreground** (tiap 15 dtk selagi app dibuka) + **refresh saat app
  di-resume** menjadi backstop: kalau alarm OS meleset (Doze/hemat baterai),
  notifikasi + feed tetap muncul begitu app aktif.
- **Tandai selesai** → reminder tugas itu dibatalkan + feed `completed`.
- **Hapus tugas** → reminder dibatalkan + baris feed ikut terhapus (cascade).
- Izin `POST_NOTIFICATIONS` + **Alarm & pengingat** (exact alarm) diminta otomatis
  saat home dibuka. Tanpa exact alarm, notifikasi bisa telat beberapa menit.

> **Batasan:** kalau app di-*kill* total DAN HP dalam mode Doze/hemat
> baterai agresif (Xiaomi/Samsung dsb), alarm OS bisa tertunda/hilang — itu
> batasan Android, bukan bug. Solusi pasti "push walau app mati": FCM dari
> server + cron (di luar cakupan tugas). Untuk demo: izinkan exact alarm +
> matikan optimasi baterai untuk Julidline, atau biarkan app tetap terbuka.

> Reminder lokal **tidak jalan di web** (otomatis no‑op). Untuk demo pakai
> emulator/HP Android.

### Mengaktifkan Push FCM (opsional)

Tanpa Firebase, `FcmService.init` menangkap error dan push sekadar nonaktif.
Untuk mengaktifkan:

### Cara cepat (disarankan) — FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pilih project Firebase dan platform Android/iOS. CLI akan membuat
`lib/firebase_options.dart` dan menaruh `google-services.json`.
Lalu ubah `data/services/fcm_service.dart`:

```dart
import '../../firebase_options.dart';
// ...
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Cara manual (Android)

1. Firebase Console → tambah app Android, `applicationId` = `com.julidline.app`.
2. Unduh `google-services.json` → taruh di `android/app/`.
3. `android/settings.gradle.kts`, di blok `plugins { }` tambahkan:
   ```kotlin
   id("com.google.gms.google-services") version "4.4.2" apply false
   ```
4. `android/app/build.gradle.kts`, di blok `plugins { }` tambahkan:
   ```kotlin
   id("com.google.gms.google-services")
   ```
5. `flutter clean && flutter run`.

### Mengirim notifikasi uji

Firebase Console → **Messaging → Create campaign → Notification** → kirim ke
device token (lihat log `FCM token: ...` di console saat app pertama jalan).

---

## 3. Menjalankan

1. Salin `assets/env.example.json` → `assets/env.json`, isi `SUPABASE_URL` &
   `SUPABASE_ANON_KEY`. (`assets/env.json` di-gitignore, tapi ikut ter-bundle
   sebagai asset sehingga dibaca otomatis saat app start.)
2. Pilih device — untuk demo notifikasi pakai **Android**:
   `flutter emulators --launch Medium_Phone_API_36.1`
3. Jalankan:

```bash
flutter pub get
flutter run                                  # cukup ini; kredensial dari assets/env.json
# atau eksplisit:
flutter run --dart-define-from-file=assets/env.json
```

Di VS Code cukup tekan **F5** (config "Julidline (debug)" di `.vscode/launch.json`).

Analisis & test:

```bash
flutter analyze
flutter test
```

## 4. Reset password (deep link)

Flow lengkap dari email sampai layar "buat password baru":

1. Layar **Lupa Password** → `AuthRepository.resetPassword(email)` memanggil
   `resetPasswordForEmail(email, redirectTo: 'io.supabase.roastline://login-callback/')`.
2. Supabase kirim email; link-nya balik ke app lewat deep link
   (di-daftarkan di `AndroidManifest.xml` intent-filter + `ios/Runner/Info.plist`
   `CFBundleURLTypes`). URL `io.supabase.roastline://login-callback/` **harus
   ada di Redirect URLs allowlist** (Setup Supabase langkah 5).
3. `supabase_flutter` otomatis memproses link, membuat sesi sementara, lalu
   `onAuthStateChange` mengeluarkan `AuthChangeEvent.passwordRecovery`.
4. `AuthController._onAuthChange` menyalakan `recoveryMode` → `_AuthGate`
   menampilkan `NewPasswordPage` (bukan Home).
5. User isi password baru → `AuthController.changePassword` →
   `auth.updateUser(UserAttributes(password: ...))` → sukses → logout →
   kembali ke Login untuk masuk dengan password baru.

> Untuk user yang **sudah login**, ada juga menu **Profil → Ganti Password**
> (tanpa email, langsung `updateUser`).

Uji deep link tanpa email (emulator/HP):
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "io.supabase.roastline://login-callback/#access_token=X&refresh_token=Y&type=recovery"
```

## Bagaimana notifikasi bekerja (ringkas kode)

| Peristiwa | File | Efek |
|---|---|---|
| App/home dibuka | `HomePage.initState` | minta izin notifikasi, `loadTasks()` |
| `loadTasks()` selesai | `TaskController._afterTasksChanged` | jadwalkan reminder tiap tugas aktif + `NotificationController.syncFromTasks` |
| Tambah tugas | `TaskController.addTask` | feed `task_added` → `NotificationRepository.create(kind:'task_added')`; reminder dijadwalkan |
| Jadwal reminder | `NotificationService.scheduleForTask` | `zonedSchedule` untuk slot H‑24/H‑6/H‑1/deadline yang masih future (id notifikasi deterministik per tugas+slot) |
| Sweep feed | `NotificationRepository.sweepReminders` | untuk ambang yang lewat *setelah tugas dibuat*, upsert baris (`onConflict: id_tasks,kind`, idempoten) |
| Tandai selesai | `TaskController.toggleCompleted` | `NotificationService.cancelForTask` + feed `completed` |
| Hapus tugas | `TaskController.deleteTask` | `cancelForTask` + baris `notifications` ikut terhapus (FK cascade) |
| Logout | `TaskController.clear` | `NotificationService.cancelAll` |
| Pesan FCM foreground | `FcmService._onForegroundMessage` | tampilkan notifikasi lokal + feed `push` |

**Tips demo cepat:** buat tugas dengan deadline **~2 menit dari sekarang**.
Slot `due` dijadwalkan; minimize app; ± saat deadline HP memunculkan notifikasi
roast. Buka lagi app → cek halaman **Notifikasi**, entri `due`/`overdue` muncul.

## Ikon & Splash

Sudah di-generate. Kalau mau regenerate setelah ganti `assets/branding/icon.png`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Sumber gambar dibuat oleh `tool/make_icon.py` (butuh `pip install Pillow`).

## Catatan

- `minSdk` mengikuti default Flutter (24). `flutter_local_notifications` butuh
  `coreLibraryDesugaring` — sudah diaktifkan di `android/app/build.gradle.kts`.
- Reminder lokal butuh izin exact alarm di sebagian Android; kalau ditolak,
  otomatis fallback ke mode longgar (`inexactAllowWhileIdle`).
