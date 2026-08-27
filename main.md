## Alur Kerja

1. Cek lingkungan – Java (OpenJDK 17/21), Node.js, npm, Android SDK.
2. Input user – Nama Aplikasi, Package ID, Logo (opsional), Versi Name, Versi Code.
3. Setup Keystore – Buat atau gunakan keystore yang sudah ada (disimpan sebagai release.keystore).
4. Inisialisasi Capacitor – Buat project Android dari web app.
5. Proses Logo – Generate icon & splash screen dengan @capacitor/assets.
6. Build APK – Compile dan sign APK release.
7. Bersih-bersih – Hapus folder temporary, simpan log.

## Prasyarat

- Java OpenJDK (openjdk-21 bukan yang openjdk-25)
  sudo apt install openjdk-21-jdk
- Node.js v16+ & npm
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install -y nodejs
- Android SDK (otomatis diunduh jika belum ada)
- wget, unzip, keytool (biasanya sudah tersedia)

Script hanya berjalan di Linux (termasuk WSL2).

## Cara Penggunaan

1. Siapkan folder website statis (berisi index.html, CSS, JS, dll).
2. Beri izin eksekusi: chmod +x build-apk.sh
3. Jalankan: ./build-apk.sh /path/to/webapp
4. Ikuti petunjuk interaktif:
   - Nama Aplikasi (boleh spasi)
   - Package ID (unik, contoh: com.yourname.app)
   - Path Logo (opsional, gunakan path absolut, misal: /home/user/Pictures/logo.png)
   - Versi Name (contoh: 1.0.0)
   - Versi Code (integer, harus naik setiap update)
   - Isi data keystore (hanya pertama kali)
5. Tunggu hingga selesai. APK siap di folder output/.

## Catatan Penting

- Simpan release.keystore dengan aman. Jika hilang, Anda tidak bisa update aplikasi di Play Store.
- Version Code harus selalu lebih tinggi dari versi sebelumnya.
- Logo minimal 512x512 px, format PNG/JPG/WebP.
- APK sudah ditandatangani dan siap upload ke Play Store.
- Pastikan akun Google Play Developer sudah siap ($25 sekali).

## Pemecahan Masalah Umum

- Java not found: Install OpenJDK 21 dan set JAVA_HOME.
- Android SDK gagal: Download manual dari developer.android.com, ekstrak ke $HOME/Android/Sdk/cmdline-tools/latest.
- Gradle build failed: Cek log build-log-*.log, cari error di file web.
- Logo tidak berubah: Gunakan path absolut, pastikan ukuran minimal 512x512.
- Keystore password lupa: Tidak bisa dipulihkan. Backup keystore dan password.

## Struktur Output

- output/app.apk (APK yang dibuat)
- release.keystore (kunci)
- build-log-*.log (Log proses build)

## Referensi & Dukungan

- **Repository**: https://github.com/neveerlabs/apkify/
- **Email**: userlinuxorg@gmail.com

---
