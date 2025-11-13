begin
  $redis = Redis.new(path: "/home/siberdir/redis.sock")
  # Test koneksi
  $redis.ping
rescue Redis::CannotConnectError => e
  Rails.logger.error "Tidak dapat terhubung ke Redis: #{e.message}"
  $redis = nil
end