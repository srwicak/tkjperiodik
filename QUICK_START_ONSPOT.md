# ⚡ Quick Start: Enable Pendaftaran Langsung

## 📋 Checklist Aktivasi (5 Menit)

### ✅ Step 1: Buat/Edit Ujian (1 menit)
1. Login ke dashboard admin
2. Menu: **Kelola** → **Ujian**
3. Klik **Edit** pada ujian yang diinginkan (atau buat baru)

### ✅ Step 2: Enable Feature (30 detik)
1. Scroll ke bawah form
2. **Centang** checkbox: ☑️ **"Izinkan Pendaftaran Langsung (On-the-Spot)"**
3. Pastikan **Status Ujian**: `Aktif`
4. Klik **Simpan**

### ✅ Step 3: Setup Jadwal Ujian (1 menit)
1. Klik **Jadwal** di menu ujian
2. Pastikan ada jadwal dengan **tanggal hari ini**
3. Pastikan ada **kuota tersedia** di sesi

### ✅ Step 4: Get URL (30 detik)
1. Lihat **Slug** ujian (contoh: `tkj-2025-sem1`)
2. Buat URL: 
   ```
   https://tkjperiodik.com/pendaftaran-langsung/SLUG-UJIAN
   ```

### ✅ Step 5: Test & Share (2 menit)
1. **Test**: Buka URL di browser (tanpa login)
2. **Verify**: Form muncul dengan lengkap
3. **Share**: Kirim URL ke peserta atau print QR code

---

## 🚀 Quick Test

### Test 1: Akses URL
```bash
# Buka di browser:
https://tkjperiodik.com/pendaftaran-langsung/[SLUG-ANDA]

# Expected: Muncul form pendaftaran
# If error: Cek checkbox & status ujian
```

### Test 2: Fill Form
```
NRP/NIP: 12345678 (atau 123456789012345678)
Password: [buat password baru]
Nama: JOHN DOE
Tanggal Lahir: 15-08-1990
Gender: Pria/Wanita
[Pangkat auto-muncul setelah isi NRP/NIP]
Jabatan: STAFF
Kesatuan: [Pilih dari dropdown]
TB: 170
BB: 70

# Expected: Golongan usia muncul otomatis
# Expected: Submit berhasil → redirect ke halaman sukses
```

### Test 3: Download PDF
```
# Di halaman sukses:
Klik: "Unduh Berkas Pendaftaran (PDF)"

# Expected: PDF ter-download
# Expected: PDF berisi data peserta lengkap
```

---

## ⚠️ Troubleshooting Cepat

### Problem: URL redirect ke home
**Fix**: 
- Cek checkbox "Izinkan Pendaftaran Langsung" sudah dicentang ✓
- Cek status ujian = Aktif ✓
- Cek ada jadwal hari ini ✓

### Problem: Form tidak muncul
**Fix**:
- Clear cache browser (Ctrl+Shift+Del)
- Coba browser lain
- Cek JavaScript enabled

### Problem: Pangkat tidak muncul
**Fix**:
- Isi NRP/NIP dulu (8 atau 18 digit)
- Wait 1 detik, pangkat akan muncul otomatis
- Refresh browser jika masih kosong

### Problem: Golongan tidak hitung
**Fix**:
- Isi tanggal lahir lengkap (DD-MM-YYYY)
- Pastikan format benar: 15-08-1990
- Golongan muncul otomatis setelah tahun diisi

### Problem: Submit error
**Fix**:
- Cek semua field required sudah diisi
- Cek format tanggal benar
- Cek NRP/NIP hanya angka
- Cek TB & BB angka valid

---

## 📱 Share ke Peserta

### Option A: WhatsApp
```
Copy & paste:

Pendaftaran ujian hari ini:
https://tkjperiodik.com/pendaftaran-langsung/[SLUG]

Isi form → Submit → Download PDF
```

### Option B: QR Code
```
1. Buka: https://www.qr-code-generator.com/
2. Paste URL pendaftaran
3. Generate & download QR code
4. Print & tempel di lokasi ujian
```

### Option C: SMS Blast
```
Template SMS:
Daftar ujian TKJ: tkjperiodik.com/pendaftaran-langsung/[SLUG]
```

---

## 🔐 Security Notes

✅ **Safe to Share Publicly**
- URL can be accessed without login
- Auto-create account on first registration
- Only works on exam day (automatic protection)
- Auto-redirect if exam full or disabled

⚠️ **Do NOT Share**
- Admin dashboard URLs
- Login credentials
- Database backup files

---

## 📞 Need Help?

### Quick Support Checklist
- [ ] Sudah cek checkbox enabled?
- [ ] Sudah cek status ujian aktif?
- [ ] Sudah cek jadwal hari ini?
- [ ] Sudah test URL di browser?
- [ ] Sudah clear cache browser?

### Still Need Help?
- **Call**: [Nomor support]
- **WhatsApp**: [Nomor WA]
- **Email**: support@tkjperiodik.com

---

## 📊 Monitor Usage

### Check Registration Stats
1. Login dashboard
2. Menu: **Kelola** → **Ujian**
3. Klik ujian → Lihat **Peserta**
4. Filter by registration date = today

### Check Session Capacity
1. Buka detail ujian
2. Lihat **Jadwal**
3. Cek **Kuota Terisi / Kuota Maksimal**

---

## 🎯 Best Practices

### DO ✅
- ✅ Enable fitur H-0 ujian (pagi hari)
- ✅ Print QR code & tempel di lokasi strategis
- ✅ Brief petugas tentang URL & cara daftar
- ✅ Prepare device (tablet/laptop) untuk assist peserta
- ✅ Monitor kuota real-time

### DON'T ❌
- ❌ Enable terlalu jauh sebelum hari ujian
- ❌ Lupa disable setelah ujian selesai
- ❌ Share URL tanpa test dulu
- ❌ Lupa brief petugas lokasi

---

**Quick Reference Card** - Print & keep at registration desk

```
┌────────────────────────────────────────┐
│  PENDAFTARAN LANGSUNG (ON-THE-SPOT)   │
├────────────────────────────────────────┤
│                                        │
│  URL: tkjperiodik.com/pendaftaran-     │
│       langsung/[SLUG-UJIAN]            │
│                                        │
│  ATAU SCAN QR CODE ↓                   │
│                                        │
│  [    QR CODE PRINT DISINI    ]       │
│                                        │
├────────────────────────────────────────┤
│  LANGKAH PENDAFTARAN:                  │
│  1. Buka URL / Scan QR                 │
│  2. Isi form lengkap                   │
│  3. Submit                             │
│  4. Download PDF                       │
│  5. Bawa PDF saat ujian                │
├────────────────────────────────────────┤
│  BUTUH BANTUAN?                        │
│  Tanya petugas di meja registrasi     │
└────────────────────────────────────────┘
```

---

**Last Updated**: November 17, 2025
