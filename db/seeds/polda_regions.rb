# db/seeds/polda_regions.rb

poldas = [
  "Polda Aceh",
  "Polda Sumatera Utara",
  "Polda Sumatera Barat",
  "Polda Riau",
  "Polda Kepulauan Riau",
  "Polda Jambi",
  "Polda Sumatera Selatan",
  "Polda Bangka Belitung",
  "Polda Bengkulu",
  "Polda Lampung",
  "Polda Banten",
  "Polda Metro Jaya",
  "Polda Jawa Barat",
  "Polda Jawa Tengah",
  "Polda Daerah Istimewa Yogyakarta",
  "Polda Jawa Timur",
  "Polda Bali",
  "Polda Nusa Tenggara Barat",
  "Polda Nusa Tenggara Timur",
  "Polda Kalimantan Barat",
  "Polda Kalimantan Tengah",
  "Polda Kalimantan Selatan",
  "Polda Kalimantan Timur",
  "Polda Kalimantan Utara",
  "Polda Sulawesi Utara",
  "Polda Gorontalo",
  "Polda Sulawesi Tengah",
  "Polda Sulawesi Barat",
  "Polda Sulawesi Selatan",
  "Polda Sulawesi Tenggara",
  "Polda Maluku",
  "Polda Maluku Utara",
  "Polda Papua",
  "Polda Papua Barat",
  "Polda Papua Tengah",
  "Polda Papua Pegunungan"
]

poldas.each do |name|
  slug = name.gsub("Polda ", "").parameterize
  PoldaRegion.find_or_create_by!(name: name, slug: slug)
end

puts "#{PoldaRegion.count} polda regions created."