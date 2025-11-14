# Configure session store with SameSite policy for Safari/Apple compatibility
Rails.application.config.session_store :cookie_store, 
  key: '_pangkat_session',
  same_site: :lax,  # Required for Safari compatibility
  secure: Rails.env.production?,  # HTTPS only in production
  httponly: true,  # Security: prevent JavaScript access
  expire_after: 14.days
