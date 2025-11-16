# Fitur Pendaftaran Langsung (On-the-Spot Registration)

## Deskripsi
Fitur ini memungkinkan peserta untuk mendaftar ujian secara langsung pada hari pelaksanaan ujian (H-0) dengan membuat akun dan mendaftar ujian dalam satu langkah.

## Cara Mengaktifkan

### 1. Melalui Form Ujian
Saat membuat atau mengedit ujian di dashboard admin:
1. Buka halaman **Kelola** → **Ujian**
2. Pilih ujian yang ingin diaktifkan fitur on-spot atau buat ujian baru
3. Centang checkbox **"Izinkan Pendaftaran Langsung (On-the-Spot)"**
4. Simpan ujian

### 2. Status Ujian
Pastikan:
- Status ujian: **Aktif**
- Ada jadwal ujian untuk hari ini (exam_schedule dengan exam_date = today)
- Ada sesi yang masih memiliki kuota (size < max_size)

## URL Akses

### Format URL
```
/pendaftaran-langsung/:exam_slug
```

### Contoh URL Production
```
https://tkjperiodik.com/pendaftaran-langsung/tkj-2025-sem1
https://tkjperiodik.com/pendaftaran-langsung/ujian-periodik-polri
https://tkjperiodik.com/pendaftaran-langsung/tes-kesehatan-polri-2025
```

### Contoh URL Development/Localhost
```
http://localhost:3000/pendaftaran-langsung/tkj-2025-sem1
http://127.0.0.1:3000/pendaftaran-langsung/ujian-abc
```

### Cara Mendapatkan Slug Ujian
1. Login sebagai admin/operator
2. Buka menu **Kelola** → **Ujian**
3. Lihat kolom **Slug** di tabel daftar ujian
4. Atau buka detail ujian, slug tampil di URL browser:
   ```
   /kelola/ujian/SLUG-DISINI
   ```

### Cara Generate URL untuk Peserta
1. Salin slug ujian (contoh: `tkj-2025-sem1`)
2. Gabungkan dengan base URL + path:
   ```
   https://tkjperiodik.com/pendaftaran-langsung/tkj-2025-sem1
   ```
3. Share URL ini ke peserta yang datang on-the-spot
4. Bisa di-print sebagai QR code atau kirim via WhatsApp

### Akses Publik (Tanpa Login)
✅ Halaman ini **dapat diakses tanpa login**
- Controller menggunakan `skip_before_action :authenticate_user!`
- Peserta tidak perlu punya akun untuk mengakses form
- Langsung bisa isi form dan daftar

### Kompatibilitas
✅ **Desktop Browser**
- Chrome ✓
- Firefox ✓
- Edge ✓
- Safari ✓

✅ **Mobile Browser**
- Safari iOS (iPhone/iPad) ✓
- Chrome Android ✓
- Chrome iOS ✓
- Firefox Mobile ✓

✅ **JavaScript Features**
- Auto-capitalize: Compatible dengan semua browser modern
- Date parsing: Compatible dengan Safari (tidak pakai optional chaining `?.`)
- Arrow functions: Diganti dengan `function()` untuk better compatibility
- `parseInt()`: Menggunakan radix 10 explicitly untuk Safari

## Flow Pendaftaran

### 1. User Baru (Belum Punya Akun)
1. Akses URL pendaftaran langsung
2. Isi form lengkap:
   - NRP (8 digit) / NIP (18 digit)
   - Kata sandi (untuk akun baru)
   - Nama lengkap (otomatis KAPITAL)
   - Tanggal lahir (DD-MM-YYYY)
   - Jenis kelamin
   - Pangkat (otomatis muncul sesuai NRP/NIP)
   - Jabatan
   - Kesatuan
   - Tinggi badan (cm)
   - Berat badan (kg)
3. Golongan usia dihitung otomatis berdasarkan tanggal lahir
4. Submit form
5. Sistem membuat:
   - User baru (status: active, verified, onboarded)
   - User detail
   - Registration untuk ujian hari ini
6. Redirect ke halaman berhasil
7. Download PDF berkas pendaftaran

### 2. User Lama (Sudah Punya Akun)
1. Akses URL pendaftaran langsung
2. Isi NRP/NIP dan kata sandi yang sudah ada
3. Sistem validasi password
4. Jika valid, langsung daftarkan ke ujian hari ini
5. Redirect ke halaman berhasil
6. Download PDF berkas pendaftaran

## Fitur Otomatis

### Auto-Capitalize
- **Nama lengkap**: Otomatis KAPITAL saat typing
- **Jabatan**: Otomatis KAPITAL saat typing

### Auto-Detect & Populate
- **Pangkat**: Dropdown pangkat terisi otomatis sesuai panjang NRP/NIP
  - 8 digit → Pangkat Polri (BHARADA, BHARATU, ..., JENDERAL)
  - 18 digit → Pangkat PNS (Juru Muda, ..., Pembina Utama)

### Auto-Calculate Golongan
- Sistem menghitung golongan usia berdasarkan:
  - Tanggal lahir peserta
  - Tanggal ujian (exam_date)
- Kategori:
  - Golongan 1: 18-30 tahun
  - Golongan 2: 31-40 tahun
  - Golongan 3: 41-50 tahun
  - Golongan 4: 51+ tahun
- Display real-time saat mengisi tanggal lahir

### Auto-Assign Session
- Sistem otomatis assign ke sesi yang:
  - Jadwalnya hari ini (exam_date = today)
  - Masih ada kuota (size < max_size)
  - Diurutkan berdasarkan waktu mulai (start_time)

## Validasi

### Server-side
- NRP harus 8 digit ATAU NIP harus 18 digit
- Tanggal lahir harus valid
- Semua field wajib diisi (kecuali email)
- Password dicek jika user sudah ada
- Cek duplikasi pendaftaran
- Cek kuota sesi tersedia

### Client-side (JavaScript)
- Format tanggal lahir DD-MM-YYYY
- Range umur 18-70 tahun
- Validasi input numerik untuk TB & BB
- Real-time calculation golongan

## Keamanan

### Access Control
- Route dapat diakses tanpa login (`skip_before_action :authenticate_user!`)
- Hanya bisa diakses jika:
  - `exam.allow_onspot_registration = true`
  - `exam.status = active`
  - Ada jadwal ujian hari ini
  - Ada sesi dengan kuota tersedia

### Password
- User baru: password disimpan terenkripsi (Devise)
- User lama: validasi password dengan `valid_password?`
- Tidak ada password complexity requirement (sesuai request)

### Rate Limiting
⚠️ **TODO**: Pertimbangkan menambahkan rate limiting untuk prevent spam registration

## PDF Generation

### Flow
1. User klik tombol "Unduh Berkas Pendaftaran"
2. Controller memanggil `GeneratePdfJob.perform_now(registration.id)` (synchronous)
3. Job generate PDF dengan:
   - Data peserta (nama, NRP/NIP, pangkat, jabatan, kesatuan)
   - Data ujian (nama, tanggal)
   - Golongan usia
   - QR code untuk quick access
4. PDF disimpan via Shrine uploader
5. Redirect ke URL download PDF

### Template
- Form A (Lembar 1): Untuk semua peserta
- Form B (Lembar 2): Hanya untuk peserta usia < 51 tahun

## Database Schema

### Tabel: exams
```ruby
add_column :exams, :allow_onspot_registration, :boolean, default: false, null: false
```

### Indexes
Tidak ada index tambahan diperlukan (menggunakan existing indexes)

## File Structure

```
app/
├── controllers/
│   └── onspot_registrations_controller.rb
├── models/
│   └── exam.rb (updated)
├── views/
│   └── onspot_registrations/
│       ├── new.html.erb
│       └── success.html.erb
├── javascript/
│   └── controllers/
│       └── onspot_form_controller.js
└── jobs/
    └── generate_pdf_job.rb (existing)

config/
└── routes.rb (updated)

db/
└── migrate/
    └── XXXXXX_add_allow_onspot_registration_to_exams.rb
```

## Testing

### Manual Testing Checklist

#### Setup
- [ ] Run migration: `rails db:migrate`
- [ ] Buat ujian baru atau edit ujian existing
- [ ] Centang checkbox "Izinkan Pendaftaran Langsung"
- [ ] Buat exam_schedule dengan exam_date = today
- [ ] Set status ujian = active

#### Test Scenario 1: User Baru
- [ ] Akses `/pendaftaran-langsung/EXAM_SLUG`
- [ ] Isi NRP 8 digit → Pangkat Polri muncul
- [ ] Isi semua field required
- [ ] Isi tanggal lahir → Golongan muncul otomatis
- [ ] Submit form
- [ ] Cek redirect ke halaman berhasil
- [ ] Cek data user di database (is_verified, is_onboarded, account_status)
- [ ] Cek data registration di database (golongan, tb, bb)
- [ ] Download PDF
- [ ] Cek PDF generated dengan data correct

#### Test Scenario 2: User Existing
- [ ] Gunakan NRP/NIP yang sudah ada
- [ ] Isi password yang benar
- [ ] Submit form
- [ ] Cek langsung terdaftar
- [ ] Cek tidak ada duplikasi user_detail

#### Test Scenario 3: Validation
- [ ] NRP/NIP invalid length → Error message
- [ ] Password salah (user existing) → Error message
- [ ] Tanggal lahir invalid → Error message
- [ ] Field required kosong → Error message
- [ ] Sudah terdaftar → Error message
- [ ] Sesi penuh → Error message
- [ ] Feature disabled (checkbox unchecked) → Redirect

#### Test Scenario 4: Edge Cases
- [ ] NIP 18 digit → Pangkat PNS muncul
- [ ] Nama dengan koma (gelar) → Format tetap benar
- [ ] Umur di boundary (30, 40, 50 tahun) → Golongan correct
- [ ] Multiple users register bersamaan → No race condition

## Troubleshooting

### Issue: Pangkat tidak muncul
**Solution**: 
- Pastikan ranks-data script tag ada di view
- Check JavaScript console untuk error
- Verify Stimulus controller loaded

### Issue: Golongan tidak terhitung
**Solution**:
- Pastikan exam_date value ada di data attribute
- Check date format ISO 8601
- Verify JavaScript calculateGolongan function

### Issue: PDF tidak generate
**Solution**:
- Check GeneratePdfJob logs
- Verify template files exist di `private/assets/templates/`
- Check Shrine uploader configuration
- Verify QR code generation dependencies

### Issue: Redirect 404
**Solution**:
- Check routes: `rails routes | grep onspot`
- Verify exam slug correct
- Check allow_onspot_registration flag

## Catatan Penting

1. **Email tidak wajib**: Sesuai request, email field dihilangkan dari form on-spot
2. **No 2FA**: User yang daftar on-spot tidak perlu setup 2FA
3. **Registration type**: Default `berkala`, tidak ada pilihan
4. **Sync PDF**: PDF di-generate synchronously saat download (bukan background job)
5. **Same day only**: Hanya bisa daftar untuk ujian hari itu juga (Date.current)

## Future Enhancements

### Nice to Have
- [ ] Rate limiting (Rack::Attack)
- [ ] CAPTCHA untuk prevent bot
- [ ] QR code scanner untuk quick registration
- [ ] SMS/WhatsApp notification dengan link pendaftaran
- [ ] Multi-language support
- [ ] Export data peserta on-spot ke Excel
- [ ] Dashboard analytics untuk on-spot registration

### Monitoring
- [ ] Track conversion rate (access vs completed registration)
- [ ] Monitor PDF generation time
- [ ] Alert jika banyak failed registration
- [ ] Daily report peserta on-spot per ujian

## Support

Jika ada pertanyaan atau issue, silakan hubungi:
- Developer: [Your contact]
- Documentation: [Link to full docs]
