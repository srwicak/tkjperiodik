source "https://rubygems.org"

ruby "3.0.4"

gem "bootsnap", require: false # Reduces boot times through caching; required in config/boot.rb
gem "caxlsx" # Excel processing
gem "combine_pdf" # Combine PDFs
gem "devise" # Authentication
gem 'devise-two-factor' # Two factor authentication
gem "docx" # Word processing
gem "fastimage" # Image processing
gem "haml" # For HAML templating
gem "rails-i18n" # Internationalization
gem "importmap-rails" # Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "jbuilder" # Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "mysql2", "~> 0.5" # Use mysql as the database for Active Record
gem "nanoid" # Generate random strings
#gem "omnidocx" # Word processing
gem "pg" # Use pgsql as the database for Active Record
gem "prawn" # PDF generation
gem "puma", ">= 5.0" # Use the Puma web server [https://github.com/puma/puma]
gem "rails", "~> 7.1.3", ">= 7.1.3.4" # Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "redis" # Use Redis adapter to run Action Cable in production
gem "rqrcode" # Generate QR codes
gem "rubyXL" # Excel processing
gem "roo" # Read Excel files
gem "shrine" # Upload files
gem "sidekiq" # Background jobs
gem "sprockets-rails"# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "stimulus-rails" # Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "tailwindcss-rails"  # Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "turbo-rails" # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ]
  gem "dotenv-rails" # Load environment variables
  gem "faker" # Generate fake data
end

group :development do
  gem "annotate" # Annotate models
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
