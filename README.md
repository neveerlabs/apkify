<div align="center">
  <b>Universal APK Builder</b>
  <p>Selamat datang di <b>Universal APK Builder</b>, sebuah tool CLI untuk mengubah website menjadi aplikasi Android siap rilis di Google Play Store</p>
</div>

## Alur Kerja (Workflow)

1. **Validasi Lingkungan**  
   Script memeriksa ketersediaan:
   - Java (pastikan OpenJDK versi yang `openjdk-21`, jangan yang `openjdk-25`)
   - Node.js & npm
   - Android SDK (diunduh otomatis jika memang belum ada)

2. **Input Pengguna**  
   Anda akan diminta input:
   - Nama Aplikasi (boleh pake space)
   - Package ID (unik, contoh: `com.company.app`)
   - Path Logo (opsional, format PNG/JPG/WebP mis: /home/neverlabs/Pictures/logo.png)
   - Versi Name (mis: `1.0.0-beta`)
   - Versi Code (integer, harus naik setiap update)

3. **Setup Keystore (Tanda Tangan Digital)**  
   - Jika belum ada, script akan membuat **keystore baru** dengan detail yang Anda masukkan.
   - Jika sudah ada, script akan meminta password dan alias untuk menggunakan keystore yang sama.
      > *Simpan file `release.keystore` di path folder script builder untuk update sementara !!!..*
   - Keystore disimpan sebagai `release.keystore` di folder script.

4. **Inisialisasi Capacitor**  
   - Membuat project Capacitor dengan konfigurasi sesuai input.
   - Menginstal dependensi yang diperlukan (`@capacitor/core`, `@capacitor/cli`, `@capacitor/android`).

5. **Pemrosesan Logo**  
   - Menggunakan library `@capacitor/assets` untuk menghasilkan icon dan splash screen di semua resolusi (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi).
   - Jika gagal, fallback ke metode manual copy ke folder `res`.

6. **Build APK Release**  
   - Menyusun file Android dengan `Gradle`.
   - Menandatangani APK dengan keystore yang sudah disiapkan.
   - Output: file `.apk` siap diupload ke Play Store.

7. **Pembersihan**  
   - Folder temporary `capacitor-project` dihapus.
   - Log disimpan untuk referensi.

## Prasyarat (Dependencies)

Pastikan sistem Anda sudah memiliki:

| Komponen | Versi Minimum | Catatan |
| :--- | :--- | :--- |
| **Java** | OpenJDK 21 | `sudo apt install openjdk-21-jdk` |
| **Node.js** | v16.x atau lebih baru | `curl -fsSL https://deb.nodesource.com/setup_20.x \| sudo -E bash - && sudo apt install -y nodejs` |
| **npm** | Terinstall bersama Node.js | - |
| **Android SDK** | - | Akan diunduh otomatis jika belum ada, namun disarankan untuk mengatur `ANDROID_SDK_ROOT` terlebih dahulu. |
| **wget**, **unzip**, **keytool** | - | Biasanya sudah tersedia di distro Linux. |

> **Catatan**: Script ini hanya berjalan di **Linux** (termasuk WSL). Untuk Windows, gunakan WSL2.

## Cara Penggunaan

1. **Siapkan folder website statis** Anda (berisi `index.html`, CSS, JS, dsb).
2. **Clone atau download** script ini dan `README.md` ke satu folder.
3. **Beri izin eksekusi** pada script:
   ```bash
   chmod +x build-apk.sh
   ```
4. Jalankan script dengan parameter path folder website:
   ```
   ./build-apk.sh /path/to/your/webapp
   ```
5. Ikuti petunjuk interaktif di layar:
   - Masukkan nama aplikasi (boleh spasi).
   - Masukkan Package ID (contoh: `com.neverlabs.myapp`).
   - Jika ingin logo, berikan path file gambar (disarankan ukuran 512x512 px).
   - Tentukan versi dan kode versi.
   - Untuk pertama kali, Anda akan diminta membuat keystore (isi data diri sesuai KTP/Perusahaan).
6. Tunggu hingga proses selesai. Hasil APK akan berada di folder `output/`.

## Catatan Penting
**Keystore (Tanda Tangan Digital)**
   - **Simpan** file `release.keystore` **dengan sangat aman**.
   - Jika Anda kehilangan atau lupa password, **Anda tidak akan bisa memperbarui aplikasi** di Play Store.
   - Gunakan **password yang kuat** dan catat di tempat terpercaya.
   - Backup keystore ke cloud atau media lain.

## Versioning
   - **Version** Code harus selalu lebih tinggi dari versi sebelumnya saat melakukan update.
   - **Version** Name bebas, bisa pakai format semantik (`1.0.0`, `1.2.3-beta`).

## Logo
   - Gunakan gambar dengan latar belakang solid atau transparan.
   - Resolusi minimal 512x512 px untuk hasil terbaik.
   - Format yang didukung: PNG, JPG, JPEG, WebP.

## Play Store Readiness
   - APK yang dihasilkan sudah **ditandatangani** dan **diproguard** (minifyEnabled false agar tidak terjadi error akibat reflection).
   - Pastikan Anda telah menyiapkan akun Google Play Developer (biaya $25 sekali).
   - Siapkan juga **Privacy Policy** dan **deskripsi aplikasi** sebelum upload.

---

## Pemecahan Masalah (Troubleshooting)

| Masalah | Kemungkinan Penyebab | Solusi |
| :--- | :--- | :--- |
| **Java not found** | OpenJDK tidak terinstall atau `JAVA_HOME` tidak diset. | Install OpenJDK 17 atau 21: <br> `sudo apt update && sudo apt install openjdk-21-jdk` <br> Setelah instalasi, tambahkan `export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64` ke `~/.bashrc` atau `~/.profile`. |
| **Android SDK not found / download gagal** | Koneksi internet tidak stabil atau URL download berubah. | Unduh secara manual dari [developer.android.com/studio#command-line-tools](https://developer.android.com/studio#command-line-tools) dan ekstrak ke `$HOME/Android/Sdk/cmdline-tools/latest`. Setelah itu, jalankan `sdkmanager --licenses` dan setujui lisensi. |
| **Gradle build failed** | Ada kesalahan pada file web (misal sintaks HTML/JS) atau konflik dependensi. | Periksa log lengkap di `build-log-*.log`. Cari kata "ERROR" atau "FAILED". Pastikan semua file web valid. Jika menggunakan framework JS, pastikan semua modul terinstall. |
| **Logo tidak berubah setelah build** | Path logo salah, atau `capacitor-assets` gagal menjalankan. | Periksa kembali path logo (gunakan path absolut). Pastikan logo berukuran minimal 512x512 dan format PNG/JPG/WebP. Script akan fallback ke manual, tapi jika tetap tidak berubah, coba hapus folder `capacitor-project` lalu jalankan ulang script. |
| **APK tidak terinstall di perangkat** | APK tidak ditandatangani dengan benar, atau versi Android tidak kompatibel. | Pastikan APK sudah ditandatangani dengan keystore yang valid. Untuk pengujian, aktifkan "Unknown sources" di pengaturan Android. Periksa juga `minSdkVersion` di `build.gradle` (default 21). |
| **Package ID sudah digunakan** | Package ID yang Anda masukkan sudah terdaftar di Play Store oleh aplikasi lain. | Ganti Package ID dengan yang unik, misal `com.namakamu.namaaplikasi`. Package ID tidak bisa diubah setelah aplikasi dirilis. |
| **Keystore password lupa** | Keystore tidak dapat diakses karena password salah atau hilang. | **Sayangnya, tidak ada cara untuk memulihkan keystore yang hilang.** Jika ini terjadi, Anda harus membuat keystore baru dan aplikasi akan dianggap sebagai aplikasi baru (tidak bisa update dari versi sebelumnya). **Simpan keystore dan password di tempat aman.** |
| **Build memakan waktu lama** | Instalasi dependensi atau download SDK pertama kali. | Proses pertama kali memang lama karena mengunduh SDK dan build tools. Untuk build berikutnya, waktu akan jauh lebih singkat karena cache sudah tersedia. |
| **`npx cap add android` gagal** | Project Capacitor tidak diinisialisasi dengan benar. | Pastikan Anda menjalankan script dari folder yang sama dengan `package.json` (atau biarkan script yang membuatnya). Hapus folder `capacitor-project` dan jalankan ulang script. |

## Tips untuk Deployment ke Play Store

1. **Siapkan Akun Google Play Developer** – Biaya pendaftaran $25 (sekali bayar). Daftar di [play.google.com/console](https://play.google.com/console).
2. **Buat AAB (Android App Bundle)** – Saat ini Google Play lebih merekomendasikan AAB daripada APK. Namun script ini menghasilkan APK yang sudah cukup. Jika ingin AAB, ubah perintah `./gradlew assembleRelease` menjadi `./gradlew bundleRelease`, lalu ambil file `.aab` dari `build/outputs/bundle/release/`.
3. **Siapkan Aset Visual** – Selain icon, Play Store membutuhkan screenshot (minimal 2), feature graphic (1024x500), dan ikon high-res (512x512). Anda bisa membuatnya dengan tool seperti Canva.
4. **Kebijakan Privasi** – Wajib memiliki halaman kebijakan privasi yang menjelaskan data apa yang dikumpulkan dan bagaimana penggunaannya. Anda bisa host di GitHub Pages atau penyedia statis lainnya.
5. **Pengisian Data di Play Console** – Isi semua bagian dengan lengkap: deskripsi, kategori, rating, dan target audiens (termasuk apakah aplikasi mengandung iklan).
6. **Pengujian Pra-rilis** – Manfaatkan fitur Open Testing atau Closed Testing untuk menguji APK pada beberapa perangkat sebelum rilis publik.
7. **Perhatikan API Level** – Pastikan `minSdkVersion` dan `targetSdkVersion` sudah sesuai. Saat ini disarankan `targetSdkVersion = 35` (Android 15).

## 📁 Struktur File dan Folder Hasil

Setelah menjalankan script, Anda akan menemukan:
```
📂 apkify/
├── 📄 build-apk.sh # Script utama
├── 📄 main.md # Buku panduan
├── 📂 output/ # Folder berisi APK
│ └── app.apk # File APK siap rilis
├── 📄 release.keystore # Keystore (jaga kerahasiaannya!)
└── 📄 build-log-YYYYMMDD-HHMMSS.log # Log proses build
```


> **⚠️ Peringatan**: Jangan pernah mengunggah `release.keystore` ke repository publik atau membagikannya ke siapa pun.

## Referensi & Sumber Daya

| Sumber | Tautan |
| :--- | :--- |
| Capacitor.js Documentation | [capacitorjs.com/docs](https://capacitorjs.com/docs) |
| Android App Signing | [developer.android.com/studio/publish/app-signing](https://developer.android.com/studio/publish/app-signing) |
| Google Play Console | [play.google.com/console](https://play.google.com/console) |
| Android SDK Command Line Tools | [developer.android.com/studio#command-line-tools](https://developer.android.com/studio#command-line-tools) |
| OpenJDK | [openjdk.org](https://openjdk.org) |

## Lisensi

Script ini dirilis di bawah lisensi **MIT**. Anda bebas menggunakan, memodifikasi, dan mendistribusikannya selama menyertakan pemberitahuan hak cipta dari pembuat asli.

> **Hak Cipta (c) 2026 NeverLabs**  
> Diberikan izin tanpa batas untuk menggunakan, menyalin, memodifikasi, menggabungkan, menerbitkan, mendistribusikan, dan menjual salinan perangkat lunak ini.

## Kontak & Dukungan

Jika Anda menemukan bug atau memiliki saran perbaikan, silakan buka *issue* di repository resmi:

- **Repository**: [https://github.com/neveerlabs/apkify](https://github.com/neveerlabs/apkify)
- **Email**: userlinuxorg@gmail.com

Atau, Anda dapat memeriksa log proses yang dihasilkan untuk mencari petunjuk kesalahan.

---

<div align="center">
  <b>Terima kasih telah menggunakan apkify !!!..</b>  
  <p><i>Semoga sukses dengan aplikasi Anda di Google Play Store.</i></p>
</div>
