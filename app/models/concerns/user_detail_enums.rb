module UserDetailEnums
  extend ActiveSupport::Concern

  included do
    enum person_status: { police: 0, staff: 1 }

    enum rank: {
      # Tamtama
      BHARADA: 0,
      BHARATU: 1,
      BHARAKA: 2,
      ABRIPDA: 3,
      ABRIPTU: 4,
      ABRIP: 5,
      # Bintara
      BRIPDA: 6,
      BRIPTU: 7,
      BRIGPOL: 8,
      BRIPKA: 9,
      AIPDA: 10,
      AIPTU: 11,
      # Perwira Pertama (Pama)
      IPDA: 12,
      IPTU: 13,
      AKP: 14,
      # Perwira Menengah (Pama)
      KOMPOL: 15,
      AKBP: 16,
      KOMBES: 17,
      # Perwira Tinggi (Pati)
      BRIGJEN: 18,
      IRJEN: 19,
      KOMJEN: 20,
      JENDERAL: 21,
    }

    # Scope atau method tambahan untuk memudahkan pengelompokan
    scope :tamtama, -> { where(rank: [ranks[:BHARADA], ranks[:BHARATU], ranks[:BHARAKA], ranks[:ABRIPDA], ranks[:ABRIPTU], ranks[:ABRIP]]) }
    scope :bintara, -> { where(rank: [ranks[:BRIPDA], ranks[:BRIPTU], ranks[:BRIGPOL], ranks[:BRIPKA], ranks[:AIPDA], ranks[:AIPTU]]) }
    scope :pama, -> { where(rank: [ranks[:IPDA], ranks[:IPTU], ranks[:AKP]]) }
    scope :pamen, -> { where(rank: [ranks[:KOMPOL], ranks[:AKBP], ranks[:KOMBES]]) }
    scope :pati, -> { where(rank: [ranks[:BRIGJEN], ranks[:IRJEN], ranks[:KOMJEN], ranks[:JENDERAL]]) }

    def group
      case rank
      when "BHARADA", "BHARATU", "BHARAKA", "ABRIPDA", "ABRIPTU", "ABRIP"
        "Tamtama"
      when "BRIPDA", "BRIPTU", "BRIGPOL", "BRIPKA", "AIPDA", "AIPTU"
        "Bintara"
      when "IPDA", "IPTU", "AKP"
        "Perwira Pertama (Pama)"
      when "KOMPOL", "AKBP", "KOMBES"
        "Perwira Menengah (Pamen)"
      when "BRIGJEN", "IRJEN", "KOMJEN", "JENDERAL"
        "Perwira Tinggi (Pati)"
      else
        "Unknown"
      end
    end

    enum unit:{
      "ITWASUM POLRI": 0,
      "BAINTELKAM POLRI": 1,
      "BAHARKAM POLRI": 2,
      "BARESKRIM POLRI": 3,
      "LEMDIKLAT POLRI": 4,
      "KORBRIMOB POLRI": 5,

      # 2025 Update
      # "SOPS POLRI": 6,
      # "SRENA POLRI": 7,
      "STAMAOPS POLRI": 6,
      "STAMARENA POLRI": 7,
      "SSDM POLRI": 8,
      "SLOG POLRI": 9,
      "SAHLI POLRI": 10,
      "DIVPROPAM POLRI": 11,
      "DIVKUM POLRI": 12,
      "DIVHUMAS POLRI": 13,
      "DIVHUBINTER POLRI": 14,
      "DIV TIK POLRI": 15,
      "KORLANTAS POLRI": 16,
      "DENSUS 88 AT POLRI": 17,
      "PUSDOKKES POLRI": 18,

      "PUSLITBANG POLRI": 19,
      "PUSKEU POLRI": 20,
      "PUSJARAH POLRI": 21,
      "SETUM POLRI": 22,
      "YANMA POLRI": 23,
      "SPRIPIM POLRI": 24,

      # 2025 Update
      "KORTASTIPIDKOR POLRI": 25,

      #TKJ UPDATE
      "LAINNYA": 26
    }
  end
end
