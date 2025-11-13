module UserDetailMappings
  extend ActiveSupport::Concern

  PERSON_MAPPING = {
    police: "POLISI REPUBLIK INDONESIA", # "Polisi Republik Indonesia",
    staff: "PEGAWAI NEGERI SIPIL", # "Pegawai Negeri Sipil",
  }

  RANK_MAPPING = {
    bripda: "Brigadir Polisi Dua",
    briptu: "Brigadir Polisi Satu",
    brigpol: "Brigadir Polisi",
    bripka: "Brigadir Polisi Kepala",
    aipda: "Ajun Inspektur Polisi Dua",
    aiptu: "Ajun Inspektur Polisi Satu",
    ipda: "Inspektur Polisi Dua",
    iptu: "Inspektur Polisi Satu",
    akp: "Ajun Komisaris Polisi",
    kompo: "Komisaris Polisi",
    akbp: "Ajun Komisaris Besar Polisi",
    kombes_pol: "Komisaris Besar Polisi",
    brigjen_pol: "Brigadir Jenderal Polisi",
    irjen_pol: "Inspektur Jenderal Polisi",
    komjen_pol: "Komisaris Jenderal Polisi",
    jendral_pol: "Jenderal Polisi",
  }

  UNIT_LONG_NAMES = {
    "ITWASUM POLRI" => "Inspektorat Pengawasan Umum",
    "BAINTELKAM POLRI" => "Badan Intelijen dan Keamanan",
    "BAHARKAM POLRI" => "Badan Pemelihara Keamanan",
    "BARESKRIM POLRI" => "Badan Reserse Kriminal",
    "LEMDIKLAT POLRI" => "Lembaga Pendidikan dan Pelatihan",
    "KORBRIMOB POLRI" => "Korps Brigade Mobil",

    # 2025 Update
    # "SOPS POLRI" => "Operasi",
    # "SRENA POLRI" => "Perencanaan dan Anggaran",
    "STAMAOPS POLRI": "Staf Utama Perencanaan Operasi",
    "STAMARENA POLRI": "Staf Utama Perencanaan Umum dan Anggaran",
    "SSDM POLRI" => "Sumber Daya Manusia",
    "SLOG POLRI" => "Logistik",
    "SAHLI POLRI" => "Staf Ahli",
    "DIVPROPAM POLRI" => "Divisi Profesi dan Pengamanan",
    "DIVKUM POLRI" => "Divisi Hukum",
    "DIVHUMAS POLRI" => "Divisi Hubungan Masyarakat",
    "DIVHUBINTER POLRI" => "Divisi Hubungan Internasional",
    "DIV TIK POLRI" => "Divisi Teknologi Informasi dan Komunikasi",
    "KORLANTAS POLRI" => "Korps Lalu Lintas",
    "DENSUS 88 AT POLRI" => "Detasemen Khusus 88 Anti Teror",
    "PUSDOKKES POLRI" => "Pusat Kedokteran dan Kesehatan",

    "PUSLITBANG POLRI" => "Pusat Penelitian dan Pengembangan",
    "PUSKEU POLRI" => "Pusat Keuangan",
    "PUSJARAH POLRI" => "Pusat Sejarah",
    "SETUM POLRI" => "Sekretariat Umum",
    "YANMA POLRI" => "Yanma (Pelayanan Markas)",
    "SPRIPIM POLRI" => "Staf Pribadi Pimpinan",

    # 2025 Update
    "KORTASTIPIDKOR POLRI" => "Korps Pemberantasan Tindak Pidana Korupsi",
  }

  def formatted_unit
    UNIT_LONG_NAMES[unit]
  end


  def formatted_person_profile
    PERSON_MAPPING[person_status.to_sym]
  end

  def formatted_rank_profile
    RANK_MAPPING[rank.to_sym]
  end
end
