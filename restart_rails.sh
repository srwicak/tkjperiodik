#!/bin/bash

LOG_FILE="rails_restart.log"
RAILS_CMD="RAILS_ENV=production rails s -p 54987"
CHECK_PROCESS=$(ps aux | grep 'puma' | grep -v grep)

# Tambahkan log waktu pengecekan
echo "$(date) - Checking Rails server..." >> $LOG_FILE

if [[ -z "$CHECK_PROCESS" ]]; then
  echo "$(date) - Rails server tidak berjalan. Memulai ulang..." >> $LOG_FILE

  # Load environment agar bisa menjalankan Rails
  #export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
  #eval "$(rbenv init -)"

  # Masuk ke folder aplikasi (script dijalankan dari dalam folder ini)
  cd "$(dirname "$0")" || exit

  # Jalankan server
  nohup $RAILS_CMD >> $LOG_FILE 2>&1 &

  echo "$(date) - Rails server telah dimulai ulang." >> $LOG_FILE
else
  echo "$(date) - Rails server masih berjalan." >> $LOG_FILE
fi

