# Fitur Toggle Operator & Jadwal Kerja

## Deskripsi
Fitur ini memungkinkan Superadmin untuk mengontrol akses operator tanpa harus menurunkan status operator mereka. Ada dua mekanisme kontrol:

1. **Toggle Status Aktif/Nonaktif** - Saklar nyala/matikan akses operator secara manual
2. **Jadwal Kerja** - Set jam kerja operator berdasarkan hari dan waktu

## Fitur Utama

### 1. Toggle Status Operator
- Superadmin bisa menonaktifkan akses operator tanpa menghapus role operator
- Operator yang dinonaktifkan tidak bisa mengakses fitur-fitur operator
- Bisa diaktifkan kembali kapan saja
- Tidak mempengaruhi Superadmin (Superadmin selalu aktif)

### 2. Jadwal Kerja Operator
- Set jam kerja operator per hari (Senin - Minggu)
- Contoh: Operator hanya bisa akses jam 08:00 - 17:00
- Jika tidak ada jadwal yang diset, operator bisa akses 24/7 (selama status aktif)
- Di luar jam kerja, operator tidak bisa mengakses fitur operator

## Cara Menggunakan

### Instalasi
1. Jalankan migration:
   ```bash
   rails db:migrate
   ```

### Mengatur Status Operator
1. Login sebagai Superadmin
2. Buka menu "Superadmin" > "Kelola Operator"
3. Di tabel operator, klik tombol:
   - **"Nonaktifkan"** (kuning) - untuk menonaktifkan operator
   - **"Aktifkan"** (hijau) - untuk mengaktifkan kembali operator

### Mengatur Jadwal Kerja
1. Di tabel operator, klik tombol **"Jadwal"** (biru)
2. Di modal yang muncul:
   - Centang hari yang ingin diset jadwalnya
   - Atur jam mulai dan jam selesai
   - Klik "Simpan"

**Contoh Pengaturan:**
- Senin - Jumat: 08:00 - 17:00
- Sabtu: 08:00 - 12:00
- Minggu: Tidak dicentang (tidak bisa akses)

### Menghapus Jadwal Kerja
Untuk mengembalikan ke akses 24/7:
1. Buka modal jadwal
2. Uncheck semua hari
3. Klik "Simpan"

## Kolom Database Baru

### Table: `user_details`
- `is_operator_active` (boolean, default: true)
  - `true`: Operator bisa akses
  - `false`: Operator tidak bisa akses
  
- `work_schedule` (jsonb, default: {})
  - Format: `{ "monday": { "start": "08:00", "end": "17:00" }, ... }`
  - Kosong berarti akses 24/7

## API Endpoints

### Toggle Status Operator
```
PATCH /superadmin/kelola/operator/:slug/toggle-status
```
**Response:**
```json
{
  "success": true,
  "is_active": true,
  "message": "Akses operator telah diaktifkan."
}
```

### Update Jadwal Kerja
```
PATCH /superadmin/kelola/operator/:slug/work-schedule
```
**Request Body:**
```json
{
  "work_schedule": {
    "monday": { "start": "08:00", "end": "17:00" },
    "tuesday": { "start": "08:00", "end": "17:00" }
  }
}
```
**Response:**
```json
{
  "success": true,
  "message": "Jadwal kerja operator berhasil diperbarui."
}
```

## Logika Validasi

### Operator Access Flow
```
1. User login
2. Cek: Apakah is_operator_granted? → Tidak → Akses ditolak
3. Cek: Apakah Superadmin? → Ya → Akses diberikan (bypass semua)
4. Cek: Apakah is_operator_active? → Tidak → Akses ditolak
5. Cek: Apakah ada work_schedule? → Tidak → Akses diberikan (24/7)
6. Cek: Apakah dalam jam kerja? → Ya → Akses diberikan
                                → Tidak → Akses ditolak
```

## Model Methods

### UserDetail Model

#### `operator_access_allowed?`
Cek apakah operator boleh akses saat ini
```ruby
user_detail.operator_access_allowed?
# => true/false
```

#### `within_work_schedule?`
Cek apakah waktu sekarang dalam jadwal kerja
```ruby
user_detail.within_work_schedule?
# => true/false
```

#### `work_schedule_status`
Dapatkan status jadwal dalam bentuk text
```ruby
user_detail.work_schedule_status
# => "Dalam jam kerja" / "Di luar jam kerja" / "Tidak ada jadwal (akses 24/7)"
```

## Catatan Penting

1. **Superadmin tidak terpengaruh**
   - Superadmin selalu bisa akses, tidak peduli status atau jadwal
   - Toggle dan jadwal hanya berlaku untuk operator biasa

2. **Default Status**
   - Saat promote operator baru, `is_operator_active` otomatis `true`
   - Operator baru bisa langsung akses (24/7)

3. **Pesan Error**
   - Operator yang akses ditolak akan melihat: "Akses operator Anda sedang dinonaktifkan atau di luar jam kerja yang ditentukan."

4. **Timezone**
   - Menggunakan `Time.current` yang mengikuti timezone aplikasi Rails
   - Pastikan timezone sudah diset dengan benar di `config/application.rb`

## Testing

### Test Manual
1. **Test Toggle Status:**
   - Promote user jadi operator
   - Nonaktifkan operator
   - Coba login sebagai operator → harus ditolak
   - Aktifkan kembali
   - Coba login lagi → harus berhasil

2. **Test Jadwal Kerja:**
   - Set jadwal operator (misal: 10:00-11:00)
   - Dalam jam tersebut → harus bisa akses
   - Di luar jam tersebut → harus ditolak
   - Hapus jadwal → harus bisa akses 24/7

## Rollback
Jika ingin rollback fitur ini:
```bash
rails db:rollback
```

## Files Yang Diubah
1. `db/migrate/20251121000000_add_operator_status_to_user_details.rb` - Migration
2. `app/models/user_detail.rb` - Model dengan helper methods
3. `app/controllers/concerns/admin_status.rb` - Validasi akses
4. `app/controllers/superadmin/promotes_controller.rb` - Controller actions
5. `config/routes.rb` - Routes baru
6. `app/views/superadmin/promotes/index.html.haml` - UI toggle & jadwal
