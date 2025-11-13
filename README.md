# Pangkat+ - Aplikasi Pendaftaran Ujian Polri (parsial)
### Oleh: SRW

## Cara menjalankan aplikasi

Aplikasi ini secara utama menggunakan bahasa pemograman [Ruby](https://www.ruby-lang.org/) dan kerangka kerja (*framework*) [Ruby on Rails](https://rubyonrails.org/). Oleh karena itu untuk menjalankan aplikasi di perangkat pengembangan lokal, saya menyarankan lingkungan pengembangan dengan langkah-langkah berikut

- [ ] Memasang WSL2 Ubuntu ([tautan tutorial eksternal](https://linuxsimply.com/linux-basics/os-installation/wsl/ubuntu-on-wsl2/)) 
- [ ] Memasang Ruby pada WSL2. Harus mengunakan manajer versi Rbenv. ([tautan tutorial eksternal](https://codex.org/2022/08/19/setting-up-ruby-wsl2.html)) 
- [ ] Memasang MySQL* pada WSL2 ([tautan tutorial eksternal](https://pen-y-fan.github.io/2021/08/08/How-to-install-MySQL-on-WSL-2-Ubuntu/))
- [ ] Memasang NginX (opsional) pada WSL2 ([tautan tutorial eksternal](https://www.youtube.com/watch?v=qh2GLaVt9x8))
- [ ] Memasang PHP ([[tautan tutorial eksternal]](https://allurcode.com/how-to-install-the-latest-php-version-on-windows-subsystem-for-linux-wsl/)), adapter MySQL untuk PHP, dan memasukkan [Adminer](https://www.adminer.org/) pada direktori server PHP

1. Unduh repository dengan cara *clone*  
Setelah semua prasyarat di atas terpenuhi langkah pertama adalah melakukan *clone* dari repositori ini, pastikan Anda telah terdaftar memiliki otoritas untuk melakukan aksi ini.

*Clone* dengan SSH
```bash
git clone git@gitlab.com:sanrawcyber/pangkat-plus.git
```

*Clone* dengan HTTPS
```bash
git clone https://gitlab.com/sanrawcyber/pangkat-plus.git
```

2. Pemasangan pustaka yang diperlukan  
Setelah mengunduh repositori ini dengan git, maka selanjutnya Anda perlu melakukan pemasangan pustaka yang digunakan dalam aplikasi ini di terminal Anda.
```bash
bundle install
```

3. Konfigurasi *environtment*
Ubah nama file `.example.env` menjadi `.env`. Kemudian ubah isi dari parameter sesuai dengan lingkungan pengembang Anda.  
Untuk kasus key, gunakan perintah
```bash
rails db:encryption:init
```  
Kemudian Anda perlu memasukkannya sesuai dengan variabelnya.

4. Buat basis data  
Setelah pemasangan pustaka dari aplikasi maka selanjutnya Anda perlu melakukan pemasangan basis data pada perangkat pengembangan lokal.
```bash
rails db:create
rails db:migrate
rails db:seed #OPSTIONAL: ini jika Anda ingin memasang data dummy
```

5. Jalankan Aplikasi
Setelah basis data aplikasi Pangkat+ dibuat maka Anda dapat menjalankan aplikasi dengan perintah.
```bash
bin/dev
```
Kemudian ikuti langkah yang diberikan, biasanya disebutkan bahwa untuk mengunjungi alamat `http://localhost:3000`

Catatan:

* *MySQL dipilih sebagai mesin basis data karena untuk mencocokan mesin basis data tempat hosting website.
* NginX menjadi opsional karena secara *default* WSL2 Ubuntu telah tersedia Apache Server. PHP digunakan untuk menjalankan Adminer, Adminer merupakan aplikasi tunggal berkas yang dapat mengatur basis data (seperti PHPMyAdmin tetapi lebih singkat).

## Informasi Teknis
Secara teknis aplikasi Pangkat+ menggunakan:
1. Versi Ruby: 3.0.4 (mengikuti versi *hosting*, dinyatakan pada file .ruby-version dan Gemfile)
2. Basis data: MySQL (mengikuti mesin basis data *hosting*)
3. Penggayaan: CSS dengan kerangka kerja [Tailwind CSS](tailwindcss.com)
4. SMTP Surel: Menggunakan akun gmail (akun ini nanti akan menjadi alamat pengiriman surel)
