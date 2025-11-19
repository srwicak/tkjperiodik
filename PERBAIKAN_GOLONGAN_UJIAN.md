# Perbaikan Masalah Golongan Ujian (Apple Device Issue)

## Deskripsi Masalah
Terdapat kasus di mana golongan ujian salah karena error JavaScript pada perangkat Apple (iOS Safari, iPadOS Safari, macOS Safari). Masalah ini disebabkan oleh perbedaan parsing tanggal di JavaScript Safari dibandingkan browser lainnya.

## Solusi yang Diimplementasikan

### 1. Backend Calculation sebagai Primary Source ✅
**File**: `app/controllers/module/exams_controller.rb` (method `create`)

**Perubahan**:
- Backend **SELALU** menghitung ulang golongan berdasarkan tanggal lahir dan tanggal ujian
- Hidden value dari JavaScript hanya digunakan sebagai referensi untuk validasi/debugging
- Jika terjadi mismatch antara frontend dan backend calculation, sistem akan:
  - Menggunakan perhitungan backend (lebih dipercaya)
  - Mencatat log warning untuk debugging

**Log yang ditambahkan**:
```ruby
# Mismatch detection
Rails.logger.warn "GOLONGAN MISMATCH for user #{@user.id}: Frontend=#{frontend_golongan}, Backend=#{backend_golongan}"

# Normal logging
Rails.logger.info "Golongan calculated by backend: #{registration.golongan} for user #{@user.id}"
```

### 2. Warning untuk Pengguna Apple Device ✅
**File**: `app/views/module/exams/new.html.haml`

**Perubahan**:
- Menambahkan deteksi Apple device menggunakan JavaScript
- Menampilkan alert warning jika user menggunakan perangkat Apple:
  ```
  ⚠️ Perangkat Apple Terdeteksi: 
  Jika Anda mengalami masalah dengan kategori golongan yang tidak sesuai, 
  silakan hubungi petugas atau gunakan perangkat lain (Android/Windows). 
  Sistem akan menghitung ulang golongan Anda di server untuk memastikan akurasi.
  ```

**Devices yang terdeteksi**:
- iPhone/iPad/iPod (iOS Safari)
- macOS (Safari browser)

### 3. Fitur Koreksi Data Ujian untuk Operator ✅
**File**: 
- `app/controllers/manage/score/scores_controller.rb` (method `update`)
- `app/views/manage/score/scores/edit.html.haml`
- `app/views/manage/score/scores/_exam_user_info.html.haml`

**Perubahan**:
- Menambahkan tombol "Koreksi Data Ujian" di halaman `/kelola/nilai/:slug/ubah`
- Operator dapat mengoreksi:
  - ✅ Tinggi Badan (TB) saat ujian
  - ✅ Berat Badan (BB) saat ujian
  - ✅ Golongan saat ujian (dengan dropdown dan informasi umur)
- Menampilkan **Umur Saat Ujian** (tahun, bulan, hari) di informasi peserta
- Modal popup dengan konfirmasi sebelum menyimpan koreksi
- Koreksi dapat dilakukan terpisah dari pengisian nilai (menggunakan parameter `correction_only`)

**UI Features**:
- Badge warna untuk golongan (hijau=1, biru=2, kuning=3, merah=4)
- Informasi umur detail (contoh: "30 tahun 5 bulan 12 hari")
- Warning alert sebelum submit: perubahan golongan akan mempengaruhi standar penilaian

## Cara Penggunaan

### Untuk Peserta Ujian:
1. Daftar ujian seperti biasa di `/ujian/:slug/daftar`
2. Jika menggunakan perangkat Apple, akan muncul warning di atas form
3. Backend akan otomatis menghitung ulang golongan yang benar
4. Jika ada masalah, hubungi operator/petugas

### Untuk Operator:
1. Buka halaman ubah nilai: `/kelola/nilai/:slug/ubah`
2. Lihat bagian "Informasi Peserta" untuk melihat data ujian
3. Klik tombol **"Koreksi Data Ujian"** (warna kuning/warning)
4. Isi data yang perlu dikoreksi:
   - TB (tinggi badan dalam cm)
   - BB (berat badan dalam kg)
   - Golongan ujian (pilih dari dropdown)
5. Sistem akan menampilkan umur detail untuk membantu validasi
6. Klik "Simpan Koreksi" dan konfirmasi
7. Data akan diupdate dan dapat langsung mempengaruhi perhitungan nilai

## Testing

### Test Case 1: Pendaftaran Normal
- User dengan DOB: 1990-01-15
- Tanggal Ujian: 2025-06-20
- Expected: Golongan 2 (umur 35 tahun)
- Backend akan menghitung dan menyimpan golongan 2

### Test Case 2: Pendaftaran Apple Device
- User dengan DOB: 1990-01-15
- Tanggal Ujian: 2025-06-20
- JavaScript mungkin error dan kirim golongan salah (misal 1)
- Backend akan override dan gunakan golongan 2 (benar)
- Log warning akan tercatat

### Test Case 3: Koreksi Operator
- Registration sudah ada dengan golongan salah (misal 3)
- Operator buka halaman ubah nilai
- Klik "Koreksi Data Ujian"
- Ubah golongan menjadi 2
- Submit → data terupdate, standar nilai berubah

## Technical Details

### Age Calculation Formula
Perhitungan umur menggunakan method `Registration.calculate_age_at_date`:
```ruby
# Menghitung tahun, bulan, dan hari
age_data = Registration.calculate_age_at_date(date_of_birth, exam_date)
# => { years: 35, months: 5, days: 5 }
```

### Golongan Category
```ruby
Registration.age_category(years)
# < 31 tahun  => '1'
# 31-40 tahun => '2'
# 41-50 tahun => '3'
# >= 51 tahun => '4'
```

### Database Schema
Table: `registrations`
- `tb` (integer): Tinggi badan dalam cm
- `bb` (integer): Berat badan dalam kg
- `golongan` (integer): Kategori umur (1-4)
- `exam_session_id` (bigint): Foreign key ke exam_sessions

## Monitoring & Debugging

### Log Files
Cek log untuk melihat mismatch dan debugging:
```bash
tail -f log/development.log | grep "GOLONGAN"
```

**Log Messages**:
- `GOLONGAN MISMATCH` - Terjadi perbedaan frontend vs backend
- `Golongan calculated by backend` - Normal calculation
- `Registration corrected` - Operator melakukan koreksi

### Database Query
Cek registrations dengan golongan mismatch:
```ruby
# Di Rails console
Registration.joins(:user).where.not(golongan: nil).find_each do |reg|
  expected = Registration.age_category(reg.age_at_exam).to_i
  if reg.golongan != expected
    puts "Mismatch: User #{reg.user_id}, Got: #{reg.golongan}, Expected: #{expected}"
  end
end
```

## Future Improvements
1. ✅ Backend calculation sebagai primary (DONE)
2. ✅ Warning untuk Apple users (DONE)
3. ✅ Koreksi data untuk operator (DONE)
4. 🔄 Batch correction tool untuk fix data lama (TODO)
5. 🔄 Dashboard analytics untuk track mismatch rate (TODO)

## Changelog
- **2025-01-XX**: Initial implementation
  - Backend primary calculation
  - Apple device warning
  - Operator correction feature
  - Age display enhancement

## Support
Jika ada masalah terkait golongan ujian:
1. Cek log file untuk error
2. Verifikasi tanggal lahir user sudah benar
3. Gunakan fitur koreksi operator jika diperlukan
4. Hubungi developer jika issue persisten

---
**Developer**: GitHub Copilot
**Date**: 2025-01-XX
**Related Files**:
- `app/controllers/module/exams_controller.rb`
- `app/controllers/manage/score/scores_controller.rb`
- `app/views/module/exams/new.html.haml`
- `app/views/manage/score/scores/edit.html.haml`
- `app/views/manage/score/scores/_exam_user_info.html.haml`
- `app/models/registration.rb`
