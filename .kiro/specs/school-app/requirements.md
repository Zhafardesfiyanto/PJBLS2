# Requirements Document

## Introduction

Aplikasi sekolah berbasis Flutter (q_les) yang menyediakan platform terpadu untuk manajemen kelas, pengumpulan dan pemberian tugas, kuis interaktif, mode ujian terkunci (exam lockdown), chat kelas, chat tugas, dan manajemen profil pengguna. Aplikasi ini ditujukan untuk dua peran utama: Guru dan Murid, dalam satu APK yang sama.

## Glossary

- **App**: Aplikasi Flutter q_les yang berjalan di perangkat Android/iOS.
- **Guru**: Pengguna dengan peran pengajar yang dapat membuat kelas, tugas, kuis, dan ujian.
- **Murid**: Pengguna dengan peran pelajar yang bergabung ke kelas dan mengerjakan tugas/ujian.
- **Kelas**: Ruang virtual yang menghubungkan Guru dan Murid, berisi tugas, kuis, ujian, dan chat.
- **Kode_Kelas**: Kode unik yang dihasilkan saat Kelas dibuat, digunakan Murid untuk bergabung ke Kelas.
- **Tugas**: Pekerjaan yang diberikan Guru kepada Murid dengan tenggat waktu tertentu.
- **Kuis**: Serangkaian pertanyaan pilihan ganda atau isian yang dapat dikerjakan Murid secara mandiri.
- **Ujian**: Sesi evaluasi formal yang dijalankan dalam Mode Ujian dengan pengawasan ketat.
- **Mode_Ujian**: Kondisi aplikasi di mana Murid tidak dapat keluar dari layar ujian sampai ujian selesai atau Guru memberikan izin.
- **Submission**: Hasil pengerjaan tugas yang dikirimkan Murid kepada Guru.
- **Chat_Kelas**: Fitur pesan teks real-time di dalam sebuah Kelas yang dapat diakses semua anggota.
- **Chat_Tugas**: Fitur pesan teks/komentar yang terikat pada sebuah Tugas tertentu, terpisah dari Chat_Kelas.
- **Gestur_Mencurigakan**: Interaksi pengguna selama Mode_Ujian yang mengindikasikan potensi kecurangan, termasuk swipe keluar aplikasi, percobaan screenshot, perpindahan aplikasi (app switch), dan percobaan membuka notifikasi.
- **Rekap_Gestur**: Catatan terstruktur berisi daftar Gestur_Mencurigakan yang dilakukan Murid selama sesi Ujian, beserta timestamp masing-masing kejadian.
- **Firebase_Auth**: Layanan autentikasi dari Firebase yang mengelola identitas pengguna (email/password) dan sesi login.
- **Firestore**: Layanan database NoSQL berbasis cloud dari Firebase yang digunakan sebagai backend utama untuk menyimpan semua data aplikasi.
- **Firebase_Storage**: Layanan penyimpanan file dari Firebase yang digunakan untuk mengunggah dan mengunduh file (misalnya lampiran tugas dan foto profil).
- **Auth_Service**: Lapisan layanan di sisi aplikasi yang memanfaatkan Firebase_Auth SDK untuk mengelola login, registrasi, dan sesi pengguna, serta menyimpan data profil pengguna (nama, peran, foto profil) ke Firestore.
- **Class_Service**: Layanan yang mengelola operasi CRUD untuk Kelas di Firestore, termasuk manajemen anggota.
- **Assignment_Service**: Layanan yang mengelola operasi CRUD untuk Tugas dan Submission di Firestore, serta file lampiran di Firebase_Storage.
- **Quiz_Service**: Layanan yang mengelola operasi CRUD untuk Kuis dan jawaban di Firestore.
- **Exam_Service**: Layanan yang mengelola sesi Ujian, Mode_Ujian, dan Rekap_Gestur di Firestore.
- **Chat_Service**: Layanan yang mengelola pengiriman dan penerimaan pesan Chat_Kelas dan Chat_Tugas secara real-time melalui Firestore.
- **Profile_Service**: Layanan yang mengelola pembaruan data profil pengguna termasuk foto profil di Firebase_Storage dan Firestore.
- **Verification_Service**: Layanan yang mengelola proses verifikasi peran Guru melalui kode verifikasi atau persetujuan Admin.
- **Admin**: Pengguna dengan peran administrator yang dapat menyetujui atau menolak permintaan verifikasi Guru.

---

## Requirements

### Requirement 1: Autentikasi Pengguna

**User Story:** Sebagai pengguna (Guru atau Murid), saya ingin dapat mendaftar dan masuk ke aplikasi, agar saya dapat mengakses fitur sesuai peran saya.

#### Acceptance Criteria

1. THE Auth_Service SHALL menyediakan dua peran pengguna: Guru dan Murid.
2. WHEN seorang pengguna mendaftar dengan email, password, nama lengkap, dan memilih peran, THE Auth_Service SHALL mendaftarkan akun ke Firebase_Auth menggunakan email dan password, kemudian menyimpan data profil pengguna (nama lengkap dan peran) ke Firestore dengan UID dari Firebase_Auth sebagai identifier.
3. IF email yang digunakan saat pendaftaran sudah terdaftar di Firebase_Auth, THEN THE Auth_Service SHALL menampilkan pesan kesalahan "Email sudah digunakan".
4. WHEN seorang pengguna memasukkan email dan password yang valid, THE Auth_Service SHALL mengautentikasi pengguna melalui Firebase_Auth, mengambil data profil pengguna dari Firestore, dan mengarahkan ke halaman utama sesuai perannya.
5. IF email atau password yang dimasukkan tidak valid, THEN THE Auth_Service SHALL menampilkan pesan kesalahan tanpa mengungkap detail mana yang salah.
6. WHEN seorang pengguna berhasil login, THE App SHALL mempertahankan sesi pengguna menggunakan mekanisme persistensi sesi Firebase_Auth sehingga pengguna tidak perlu login ulang saat membuka aplikasi kembali.
7. WHEN seorang pengguna menekan tombol logout, THE Auth_Service SHALL memanggil metode sign-out pada Firebase_Auth untuk menghapus sesi aktif dan mengarahkan pengguna ke halaman login.

---

### Requirement 2: Manajemen Kelas

**User Story:** Sebagai Guru, saya ingin membuat dan mengelola kelas, agar saya dapat mengorganisir Murid dan materi pembelajaran.

#### Acceptance Criteria

1. WHEN seorang Guru membuat Kelas baru dengan nama dan deskripsi, THE Class_Service SHALL membuat Kelas di Firestore dan menghasilkan Kode_Kelas unik yang terdiri dari 6 karakter alfanumerik.
2. THE Class_Service SHALL menampilkan daftar semua Kelas yang dimiliki atau diikuti oleh pengguna yang sedang login.
3. WHEN seorang Murid memasukkan Kode_Kelas yang valid dan menekan tombol "Gabung", THE Class_Service SHALL memverifikasi keberadaan Kelas di Firestore, menambahkan UID Murid ke daftar anggota Kelas, dan menampilkan Kelas tersebut di daftar Kelas Murid.
4. IF Kode_Kelas yang dimasukkan tidak ditemukan di Firestore, THEN THE Class_Service SHALL menampilkan pesan kesalahan "Kode kelas tidak valid".
5. IF seorang Murid mencoba bergabung ke Kelas yang sudah pernah diikutinya, THEN THE Class_Service SHALL menampilkan pesan "Kamu sudah menjadi anggota kelas ini" tanpa menduplikasi data anggota.
6. IF seorang Murid mencoba bergabung ke Kelas saat koneksi internet tidak tersedia, THEN THE App SHALL menampilkan pesan kesalahan "Tidak ada koneksi internet. Periksa koneksi dan coba lagi."
7. WHEN seorang Guru membuka halaman Kelas, THE App SHALL menampilkan daftar anggota, tugas, kuis, ujian, dan tab chat.
8. WHEN seorang Guru menghapus Kelas, THE Class_Service SHALL menghapus semua data terkait Kelas tersebut termasuk tugas, kuis, ujian, dan pesan chat.
9. WHEN seorang Guru membuka halaman daftar anggota Kelas, THE Class_Service SHALL menampilkan daftar lengkap nama semua Murid yang terdaftar beserta jumlah total anggota Murid.
10. WHEN seorang Guru menekan tombol "Keluarkan" pada salah satu Murid di daftar anggota, THE Class_Service SHALL menghapus UID Murid tersebut dari daftar anggota Kelas dan Murid tidak dapat lagi mengakses Kelas tersebut.
11. IF seorang Murid yang telah dikeluarkan mencoba mengakses Kelas tersebut, THEN THE App SHALL mengarahkan Murid ke halaman daftar Kelas dan menampilkan pesan "Kamu tidak lagi menjadi anggota kelas ini".
12. WHEN seorang Guru melihat detail Kelas, THE App SHALL menampilkan Kode_Kelas beserta tombol "Salin Kode" yang menyalin Kode_Kelas ke clipboard perangkat dan menampilkan konfirmasi "Kode berhasil disalin".
13. WHEN seorang Murid membuka halaman bergabung kelas, THE App SHALL menyediakan kolom input teks untuk memasukkan Kode_Kelas secara manual atau menempelkan (paste) kode dari clipboard.
14. WHEN seorang pengguna mengetik di kolom pencarian kelas, THE App SHALL memfilter daftar Kelas yang ditampilkan secara real-time berdasarkan nama Kelas yang mengandung teks pencarian tersebut.
15. THE App SHALL menyediakan komponen dropdown untuk memilih Kelas dari daftar Kelas yang dimiliki atau diikuti pengguna.

---

### Requirement 3: Pemberian dan Pengumpulan Tugas

**User Story:** Sebagai Guru, saya ingin memberikan tugas kepada Murid di kelas, dan sebagai Murid, saya ingin mengumpulkan tugas tersebut, agar proses belajar mengajar dapat berjalan secara digital.

#### Acceptance Criteria

1. WHEN seorang Guru membuat Tugas dengan judul, deskripsi, kategori, dan tenggat waktu, THE Assignment_Service SHALL menyimpan Tugas dan menampilkannya kepada semua Murid di Kelas tersebut.
2. THE Assignment_Service SHALL mendukung tiga kategori Tugas: pilihan ganda (satu jawaban benar), pilihan ganda kompleks (lebih dari satu jawaban benar), dan uraian (jawaban teks panjang).
3. THE Assignment_Service SHALL menampilkan status tenggat waktu Tugas (aktif atau sudah lewat) kepada Murid.
4. WHEN seorang Murid mengumpulkan Tugas dengan mengunggah file atau teks jawaban sebelum tenggat waktu, THE Assignment_Service SHALL menyimpan Submission dan menandai Tugas sebagai "Dikumpulkan".
5. IF seorang Murid mencoba mengumpulkan Tugas setelah tenggat waktu, THEN THE Assignment_Service SHALL menampilkan peringatan bahwa tenggat waktu telah lewat namun tetap mengizinkan pengumpulan terlambat.
6. WHEN seorang Guru membuka detail Tugas, THE Assignment_Service SHALL menampilkan daftar Murid yang sudah dan belum mengumpulkan Submission.
7. WHEN seorang Guru memberikan nilai pada Submission, THE Assignment_Service SHALL menyimpan nilai dan menampilkannya kepada Murid yang bersangkutan.

---

### Requirement 4: Kuis Interaktif

**User Story:** Sebagai Guru, saya ingin membuat kuis interaktif di dalam kelas, agar Murid dapat berlatih dan saya dapat mengevaluasi pemahaman mereka secara cepat.

#### Acceptance Criteria

1. WHEN seorang Guru membuat Kuis dengan judul dan menambahkan pertanyaan, THE Quiz_Service SHALL menyimpan Kuis beserta semua pertanyaan, pilihan jawaban, jawaban yang benar, dan bobot nilai per soal.
2. THE Quiz_Service SHALL mendukung tiga tipe pertanyaan: pilihan ganda (satu jawaban benar), pilihan ganda kompleks (lebih dari satu jawaban benar), dan uraian (jawaban teks panjang).
3. WHEN seorang Guru mempublikasikan Kuis, THE Quiz_Service SHALL menampilkan Kuis kepada semua Murid di Kelas tersebut.
4. WHEN seorang Murid mengerjakan dan mengirimkan Kuis, THE Quiz_Service SHALL menghitung nilai per soal berdasarkan bobot yang ditentukan Guru dan menghitung nilai keseluruhan sebagai jumlah nilai semua soal.
5. WHEN seorang Murid mengirimkan Kuis, THE Quiz_Service SHALL menampilkan rincian nilai per soal beserta jawaban yang benar dan nilai keseluruhan kepada Murid tersebut.
6. WHEN seorang Guru membuka hasil Kuis, THE Quiz_Service SHALL menampilkan rekap nilai keseluruhan semua Murid yang telah mengerjakan Kuis tersebut.
7. IF seorang Murid mencoba mengerjakan Kuis yang sama lebih dari satu kali, THEN THE Quiz_Service SHALL menampilkan hasil pengerjaan sebelumnya tanpa mengizinkan pengerjaan ulang.

---

### Requirement 5: Mode Ujian (Exam Lockdown)

**User Story:** Sebagai Guru, saya ingin mengaktifkan mode ujian yang mengunci aplikasi Murid selama ujian berlangsung, agar integritas ujian terjaga dan Murid tidak dapat mengakses aplikasi lain.

#### Acceptance Criteria

1. WHEN seorang Guru memulai sesi Ujian untuk Kelas tertentu, THE Exam_Service SHALL mengaktifkan Mode_Ujian pada perangkat semua Murid yang sedang aktif di Kelas tersebut.
2. WHILE Mode_Ujian aktif, THE App SHALL menampilkan layar ujian secara penuh (full-screen) dan mencegah navigasi keluar dari layar ujian menggunakan tombol back, home, atau recent apps pada Android.
3. WHILE Mode_Ujian aktif, THE App SHALL mendeteksi setiap percobaan Murid untuk keluar dari aplikasi dan menampilkan peringatan bahwa ujian sedang berlangsung.
4. WHILE Mode_Ujian aktif, THE Exam_Service SHALL mendeteksi dan mencatat setiap Gestur_Mencurigakan yang dilakukan Murid ke dalam Rekap_Gestur, termasuk: swipe keluar aplikasi, percobaan screenshot, perpindahan aplikasi (app switch), dan percobaan membuka panel notifikasi.
5. WHILE Mode_Ujian aktif, THE Exam_Service SHALL menyimpan setiap entri Rekap_Gestur dengan timestamp kejadian dan jenis gestur ke Firestore secara real-time.
6. WHEN seorang Guru membuka detail sesi Ujian, THE Exam_Service SHALL menampilkan Rekap_Gestur per Murid yang berisi daftar semua Gestur_Mencurigakan beserta timestamp masing-masing kejadian.
7. WHEN seorang Murid menyelesaikan semua soal ujian dan menekan tombol "Kumpulkan Ujian", THE Exam_Service SHALL menonaktifkan Mode_Ujian pada perangkat Murid tersebut.
8. WHEN seorang Guru menekan tombol "Akhiri Ujian" untuk Murid tertentu atau seluruh kelas, THE Exam_Service SHALL menonaktifkan Mode_Ujian pada perangkat Murid yang bersangkutan.
9. IF koneksi internet Murid terputus selama Mode_Ujian aktif, THEN THE App SHALL menyimpan jawaban ujian dan Rekap_Gestur secara lokal dan menampilkan indikator bahwa perangkat sedang offline.
10. WHEN koneksi internet Murid pulih selama Mode_Ujian aktif, THE Exam_Service SHALL mengunggah jawaban dan Rekap_Gestur yang tersimpan secara lokal ke Firestore secara otomatis.

---

### Requirement 6: Chat Kelas

**User Story:** Sebagai anggota Kelas (Guru atau Murid), saya ingin dapat mengirim dan menerima pesan teks di dalam Kelas, agar komunikasi terkait pembelajaran dapat berlangsung dalam satu platform.

#### Acceptance Criteria

1. WHEN seorang anggota Kelas mengirim pesan teks di tab Chat_Kelas, THE Chat_Service SHALL menyimpan pesan dan mengirimkannya kepada semua anggota Kelas yang aktif secara real-time.
2. THE Chat_Service SHALL menampilkan nama pengirim, foto profil pengirim, isi pesan, dan waktu pengiriman untuk setiap pesan di Chat_Kelas.
3. WHEN seorang anggota Kelas membuka tab Chat_Kelas, THE Chat_Service SHALL memuat riwayat pesan Kelas tersebut.
4. IF panjang pesan Chat_Kelas melebihi 1000 karakter, THEN THE Chat_Service SHALL menampilkan pesan kesalahan dan mencegah pengiriman.
5. WHILE Mode_Ujian aktif, THE App SHALL menonaktifkan akses ke tab Chat_Kelas untuk Murid yang sedang mengerjakan ujian.
6. WHEN seorang Guru menghapus pesan di Chat_Kelas, THE Chat_Service SHALL menghapus pesan tersebut dari tampilan semua anggota Kelas.

---

### Requirement 7: Chat Tugas

**User Story:** Sebagai Guru atau Murid, saya ingin dapat berdiskusi langsung di dalam sebuah Tugas, agar pertanyaan dan klarifikasi terkait tugas tersebut tidak tercampur dengan Chat_Kelas umum.

#### Acceptance Criteria

1. WHEN seorang anggota Kelas membuka detail sebuah Tugas, THE App SHALL menampilkan kolom Chat_Tugas yang terpisah dari Chat_Kelas.
2. WHEN seorang anggota Kelas mengirim pesan di kolom Chat_Tugas, THE Chat_Service SHALL menyimpan pesan yang terikat pada ID Tugas tersebut dan mengirimkannya kepada semua anggota Kelas secara real-time.
3. THE Chat_Service SHALL menampilkan nama pengirim, isi pesan, dan waktu pengiriman untuk setiap pesan di Chat_Tugas.
4. WHEN seorang anggota Kelas membuka detail Tugas, THE Chat_Service SHALL memuat riwayat pesan Chat_Tugas untuk Tugas tersebut.
5. IF panjang pesan Chat_Tugas melebihi 1000 karakter, THEN THE Chat_Service SHALL menampilkan pesan kesalahan dan mencegah pengiriman.
6. WHEN seorang Guru menghapus pesan di Chat_Tugas, THE Chat_Service SHALL menghapus pesan tersebut dari tampilan semua anggota Kelas.

---

### Requirement 8: Manajemen Profil Pengguna

**User Story:** Sebagai pengguna, saya ingin dapat memperbarui foto profil saya, agar identitas saya di dalam aplikasi dapat mencerminkan diri saya.

#### Acceptance Criteria

1. WHEN seorang pengguna membuka halaman profil, THE App SHALL menampilkan foto profil saat ini, nama lengkap, email, dan peran pengguna.
2. WHEN seorang pengguna menekan tombol "Ubah Foto Profil" dan memilih gambar dari galeri atau kamera, THE Profile_Service SHALL mengunggah gambar ke Firebase_Storage dan memperbarui URL foto profil di Firestore.
3. IF ukuran file gambar yang dipilih melebihi 5 MB, THEN THE Profile_Service SHALL menampilkan pesan kesalahan "Ukuran file terlalu besar. Maksimal 5 MB." dan membatalkan proses unggah.
4. IF format file gambar yang dipilih bukan JPEG, PNG, atau WebP, THEN THE Profile_Service SHALL menampilkan pesan kesalahan "Format file tidak didukung. Gunakan JPEG, PNG, atau WebP."
5. WHEN pembaruan foto profil berhasil, THE App SHALL menampilkan foto profil baru secara langsung di halaman profil dan di semua pesan Chat yang dikirim pengguna tersebut.

---

### Requirement 9: Verifikasi Peran Guru

**User Story:** Sebagai Admin, saya ingin memverifikasi bahwa pengguna yang mendaftar sebagai Guru memang benar-benar seorang guru, agar tidak ada penyalahgunaan peran Guru oleh pihak yang tidak berwenang.

#### Acceptance Criteria

1. WHEN seorang pengguna mendaftar dengan peran Guru, THE Verification_Service SHALL membuat permintaan verifikasi dengan status "Menunggu" di Firestore dan menampilkan notifikasi kepada pengguna bahwa akun sedang dalam proses verifikasi.
2. WHILE status verifikasi Guru adalah "Menunggu", THE App SHALL membatasi akses Guru sehingga hanya dapat melihat kelas yang sudah ada tanpa dapat membuat Kelas, Tugas, Kuis, atau Ujian baru.
3. WHEN seorang Admin membuka halaman manajemen verifikasi, THE Verification_Service SHALL menampilkan daftar semua permintaan verifikasi Guru dengan status "Menunggu".
4. WHEN seorang Admin menyetujui permintaan verifikasi Guru, THE Verification_Service SHALL memperbarui status verifikasi menjadi "Terverifikasi" di Firestore dan mengirimkan notifikasi kepada Guru bahwa akun telah diverifikasi.
5. WHEN seorang Admin menolak permintaan verifikasi Guru, THE Verification_Service SHALL memperbarui status verifikasi menjadi "Ditolak" di Firestore, mengirimkan notifikasi kepada Guru beserta alasan penolakan, dan meminta Guru untuk mengajukan ulang dengan informasi yang benar.
6. IF seorang Guru dengan status "Ditolak" mencoba membuat Kelas baru, THEN THE App SHALL menampilkan pesan "Akun Guru kamu belum terverifikasi. Hubungi Admin untuk informasi lebih lanjut."
7. WHERE fitur kode verifikasi institusi tersedia, THE Verification_Service SHALL menerima kode verifikasi institusi yang dimasukkan Guru saat pendaftaran sebagai salah satu metode verifikasi otomatis tanpa perlu persetujuan manual Admin.

---

### Requirement 10: Notifikasi

**User Story:** Sebagai pengguna, saya ingin menerima notifikasi untuk aktivitas penting di kelas saya, agar saya tidak melewatkan tugas, kuis, atau ujian baru.

#### Acceptance Criteria

1. WHEN seorang Guru membuat Tugas baru di sebuah Kelas, THE App SHALL mengirimkan notifikasi push kepada semua Murid di Kelas tersebut.
2. WHEN seorang Guru mempublikasikan Kuis baru di sebuah Kelas, THE App SHALL mengirimkan notifikasi push kepada semua Murid di Kelas tersebut.
3. WHEN seorang Guru memulai sesi Ujian, THE App SHALL mengirimkan notifikasi push kepada semua Murid di Kelas tersebut.
4. WHEN tenggat waktu Tugas kurang dari 24 jam, THE App SHALL mengirimkan notifikasi pengingat kepada Murid yang belum mengumpulkan Tugas tersebut.
5. WHEN permintaan verifikasi Guru disetujui atau ditolak oleh Admin, THE App SHALL mengirimkan notifikasi push kepada Guru yang bersangkutan.
