Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get 'server-time', to: 'time#current'

  root "dashboard#index"

  # Public result report access
  get 'hasil-ujian/:slug', to: 'module/scores#view_result_report', as: :public_result_report

  mount ActionCable.server => "/cable"
  
  # API endpoints
  namespace :api do
    get 'scoring_standards', to: 'scoring_standards#show'
    get 'scoring_standards/all', to: 'scoring_standards#index'
  end

  scope "/" do

    # On-spot registration for same-day exams
    scope "pendaftaran-langsung" do
      get "/:exam_slug", to: "onspot_registrations#new", as: :new_onspot_registration
      post "/:exam_slug", to: "onspot_registrations#create", as: :create_onspot_registration
      get "/:exam_slug/berhasil/:registration_slug", to: "onspot_registrations#success", as: :success_onspot_registration
      get "/:exam_slug/berhasil/:registration_slug/unduh", to: "onspot_registrations#download", as: :download_onspot_registration
    end

    scope "ujian" do
      get "/", to: "module/exams#index", as: :index_module_exam
      get "/:slug", to: "module/exams#show", as: :show_module_exam
      get "/:slug/daftar", to: "module/exams#new", as: :new_module_exam
      post "/:slug/daftar", to: "module/exams#create"
    end

    scope "riwayat" do
      get "/", to: "module/histories#index", as: :index_module_history
      get "/:slug", to: "module/histories#show", as: :show_module_history
      get "/:slug/unduh", to: "module/histories#download_pdf", as: :download_pdf_module_history
    end

    scope "profil" do
      get "/", to: "module/profiles#edit", as: :edit_module_profile
      patch "/", to: "module/profiles#update"
      put "/", to: "module/profiles#update"
    end

    # 2025 Update
    scope "hasil" do
      post "buat/:slug", to: "module/scores#generate_result_report", as: :generate_result_report
      get "lihat/:slug", to: "module/scores#view_result_report", as: :result_report_slug
    end


    ### EOF 2025

    get "", to: "dashboard#index", as: :index_dashboard
    get "menunggu-akun", to: "static#waiting", as: :waiting_static

    get "masuk/keamanan-akun", to: "twofactorauth#show_otp", as: :show_otp_twofactorauth
    post "masuk/keamanan-akun", to: "twofactorauth#verify_otp", as: :verify_otp_twofactorauth

    get "keamanan-akun", to: "twofactorauth#setup", as: :setup_twofactorauth
    post "keamanan-akun", to: "twofactorauth#setup_verify", as: :twofactorauth

    get "orientasi", to: "onboarding#new", as: :new_onboarding
    post "orientasi", to: "onboarding#create", as: :create_onboarding

    get "kata-sandi/lupa", to: "users/password_resets#new", as: :new_user_password_reset
    post "kata-sandi/lupa", to: "users/password_resets#create", as: :user_password_reset

    devise_for :users, skip: [:sessions, :registrations]

    devise_scope :user do
      # Sessions
      get "masuk", to: "users/sessions#new", as: :new_user_session
      post "masuk", to: "users/sessions#create", as: :user_session
      delete "keluar", to: "users/sessions#destroy", as: :destroy_user_session

      # Registrations
      get "daftar", to: "users/registrations#new", as: :new_user_registration
      post "daftar", to: "users/registrations#create", as: :user_registration
    end

    scope "kelola" do
      scope "pendaftaran" do
        get "/:slug", to: "manage/shared/registrations#show", as: :show_manage_user_registration
      end

      scope "pengguna" do
        scope "verifikasi" do
          get "/", to: "manage/user/verifications#index", as: :index_manage_user_verification
          get "data", to: "manage/user/verifications#data", as: :data_manage_user_verification
          post "tinjau", to: "manage/user/verifications#reviewer_add", as: :add_reviewer_manage_user_verification
          post "batal", to: "manage/user/verifications#reviewer_remove", as: :remove_reviewer_manage_user_verification
          get "peninjau", to: "manage/user/verifications#reviewer_fetch", as: :fetch_reviewer_manage_user_verification
          patch "/:id", to: "manage/user/verifications#update", as: :update_manage_user_verification
        end

        scope "lupa" do
          get "/", to: "manage/user/forgots#index", as: :index_manage_user_forgot
          get "data", to: "manage/user/forgots#data", as: :data_manage_user_forgot
          patch "/:id", to: "manage/user/forgots#update", as: :update_manage_user_forgot
        end

        scope "nonaktif" do
          get "/", to: "manage/user/nonactives#index", as: :index_manage_user_nonactive
          get "data", to: "manage/user/nonactives#data", as: :data_manage_user_nonactive
          get "/:slug", to: "manage/user/nonactives#show", as: :show_manage_user_nonactive
          patch "/:slug", to: "manage/user/nonactives#update", as: :update_manage_user_nonactive
          delete "/:slug", to: "manage/user/nonactives#destroy", as: :destroy_manage_user_nonactive
          get "/:slug/ujian/:reg_slug", to: "manage/shared/registrations#show", as: :show_manage_shared_registration_nonactive
        end



        get "/", to: "manage/user/actives#index", as: :index_manage_user_active
        get "data", to: "manage/user/actives#data", as: :data_manage_user_active

        get "data-partisipasi/:slug", to: "manage/shared/registrations#data", as: :data_manage_shared_registration

        get "/:slug", to: "manage/user/actives#show", as: :show_manage_user_active
        patch "/:slug", to: "manage/user/actives#update", as: :update_manage_user_active
        get "/:slug/ubah-profil", to: "manage/user/actives#edit_profile", as: :edit_profile_manage_user_active
        patch "/:slug/ubah-profil", to: "manage/user/actives#update_profile"
        put "/:slug/ubah-profil", to: "manage/user/actives#update_profile"
        get "/:slug/ujian/:reg_slug", to: "manage/shared/registrations#show", as: :show_manage_shared_registration
      end
      
      # Fitur Lainnya - accessible by admin and operator
      scope "manajemen-pengguna" do
        get "tambah", to: "manage/user_management/users#new", as: :new_manage_user
        post "tambah", to: "manage/user_management/users#create"
      end

      scope "manajemen-peserta" do
        get "tambah", to: "manage/user_management/participants#new", as: :new_manage_participant
        post "tambah", to: "manage/user_management/participants#mass_register"
      end

      scope "manajemen-borang" do
        get "cari", to: "manage/user_management/forms#search", as: :search_manage_forms
        post "data", to: "manage/user_management/forms#data"
      end

      scope "hasil-ujian" do
        get "cetak", to: "manage/result/print_results#index", as: :index_manage_result_print_results
        post "cetak/data", to: "manage/result/print_results#data", as: :data_manage_result_print_results
      end

      scope "surat" do
        get "template/data", to: "manage/result/templates#data", as: :data_manage_result_template
        get "template/", to: "manage/result/templates#index", as: :index_manage_result_template
        get "template/:slug", to: "manage/result/templates#edit", as: :edit_manage_result_template
        patch "template/:slug", to: "manage/result/templates#update"
        put "template/:slug", to: "manage/result/templates#update"

        get "cetak/tunggal", to: "manage/result/generate_by_nrps#index", as: :index_manage_result_generate_by_nrp
        post "cetak/tunggal/data", to: "manage/result/generate_by_nrps#data", as: :data_manage_result_generate_by_nrp
        get "cetak/tunggal/data/:identity", to: "manage/result/generate_by_nrps#data", as: :data_manage_result_generate_by_nrpx

        get "cetak/massal/:slug", to: "manage/result/generate_by_exams#index", as: :index_manage_result_generate_by_exam

        get "unduh-massal/:slug/kesatuan/:unit/jenis/:type/unduh", to: "manage/result/generate_by_exams#download_docs", as: :download_manage_result_generate_by_unit_by_type

        get "cetak/massal/:slug/kesatuan/:unit", to: "manage/result/generate_by_units#index", as: :index_manage_result_generate_by_unit


        post "cetak-massal", to: "manage/result/generate_by_exams#generate_docs", as: :create_bulk_manage_result_generate_by_exam


        match "/cetak", to: redirect("kelola/surat/cetak/tunggal"), via: :all

        match "/", to: redirect("kelola/surat/template"), via: :all
      end

      scope "ujian" do
        get "/buat", to: "manage/exam/actives#new", as: :new_manage_exam_active
        post "/buat", to: "manage/exam/actives#create"
        get "/data", to: "manage/exam/actives#data", as: :data_manage_exam_active
        get "/", to: "manage/exam/actives#index", as: :index_manage_exam_active


        get "/statistik-peserta/:slug", to: "manage/exam/participants#statistic", as: :statistic_manage_exam_participant

        get "/:slug", to: "manage/exam/actives#show", as: :show_manage_exam_active

        get "/:slug/data-session", to: "manage/exam/participants#data_session", as: :data_session_manage_exam_participants

        # 2025 Update - Exam Schedules
        get "/:exam_slug/jadwal", to: "manage/exam/schedules#index", as: :manage_exam_schedules
        get "/:exam_slug/jadwal/baru", to: "manage/exam/schedules#new", as: :new_manage_exam_schedule
        post "/:exam_slug/jadwal", to: "manage/exam/schedules#create"
        get "/:exam_slug/jadwal/:id/ubah", to: "manage/exam/schedules#edit", as: :edit_manage_exam_schedule
        patch "/:exam_slug/jadwal/:id", to: "manage/exam/schedules#update", as: :manage_exam_schedule
        put "/:exam_slug/jadwal/:id", to: "manage/exam/schedules#update"
        delete "/:exam_slug/jadwal/:id", to: "manage/exam/schedules#destroy"

        get "/:slug/ubah", to: "manage/exam/actives#edit", as: :edit_manage_exam_active
        patch "/:slug/ubah", to: "manage/exam/actives#update"
        put "/:slug/ubah", to: "manage/exam/actives#update"
        delete "/:slug", to: "manage/exam/actives#destroy", as: :destroy_manage_exam_active

        get "/:slug/sesi/:session", to: "manage/exam/participants#show", as: :show_manage_exam_participant
        get "/:slug/sesi/:session/data", to: "manage/exam/participants#data", as: :data_manage_exam_participant

        get "/:slug/kesatuan/:unit", to: "manage/exam/units#show", as: :show_manage_exam_unit

        get "/:slug/kesatuan/:unit/data", to: "manage/exam/units#data", as: :manage_exam_unit_data
        
        get "/:slug/kesatuan/:unit/download-excel", to: "manage/exam/units#download_excel", as: :download_excel_manage_exam_unit

        match "/:slug/sesi", to: redirect("/kelola/ujian"), via: :all

        # 2025 Update
        get "/:slug/kesatuan/:unit/upload", to: "manage/exam/excel_uploads#create", as: :upload_manage_exam_unit
        post "/:slug/kesatuan/:unit/upload", to: "manage/exam/excel_uploads#create", as: :create_upload_manage_exam_unit
        get  "/:slug/kesatuan/:unit/upload/:id/download", to: "manage/exam/excel_uploads#download", as: :download_manage_exam_unit_excel_upload
        # scope "/:slug/kesatuan/:unit" do
        #   resources :excel_uploads,
        #             only: %i[index create],
        #             controller: 'manage/exam/units/excel_uploads' do
        #     member { get :download }
        #   end
        # end
      end

      scope "nilai" do
        get "/", to: "manage/score/scores#index", as: :index_manage_score
        post "cari", to: "manage/score/scores#search", as: :search_manage_score
        get "data", to: "manage/score/scores#data", as: :data_manage_score
        get ":code/isi", to: "manage/score/qr_access#show", as: :qr_access_manage_score, constraints: { code: /[A-Z0-9\-]+/ }
        
        # Standar Penilaian sub-menu
        scope "standar-penilaian" do
          get "/", to: "manage/score/scoring_standards#index", as: :manage_score_scoring_standards
          get "/:id/ubah", to: "manage/score/scoring_standards#edit", as: :edit_manage_score_scoring_standard
          patch "/:id", to: "manage/score/scoring_standards#update", as: :manage_score_scoring_standard
          put "/:id", to: "manage/score/scoring_standards#update"
        end
        
        get "/:slug", to: "manage/score/scores#show", as: :show_manage_score
        get "/:slug/buat-dokumen", to: "manage/score/scores#generate_doc", as: :generate_doc_manage_score
        get "/:slug/unduh", to: "manage/score/scores#download_doc", as: :download_doc_manage_score
        get "/:slug/ubah", to: "manage/score/scores#edit", as: :edit_manage_score
        patch "/:slug/ubah", to: "manage/score/scores#update"
        put "/:slug/ubah", to: "manage/score/scores#update"
      end

      scope "nilai-id" do
        get "/", to: "manage/score/score_by_nrps#index", as: :index_manage_score_by_nrp
        post "data", to: "manage/score/score_by_nrps#data", as: :data_manage_score_by_nrp
      end

      scope "polda" do
        scope "daerah" do
          get "/", to: "manage/polda/regions#index", as: :index_manage_polda_region
          get "tambah", to: "manage/polda/regions#new", as: :new_manage_polda_region
          post "tambah", to: "manage/polda/regions#create", as: :create_manage_polda_region
          get "data", to: "manage/polda/regions#data", as: :data_manage_polda_region
          get "/:slug", to: "manage/polda/regions#show", as: :show_manage_polda_region
          get "/:slug/ubah", to: "manage/polda/regions#edit", as: :edit_manage_polda_region
          patch "/:slug/ubah", to: "manage/polda/regions#update"
          put "/:slug/ubah", to: "manage/polda/regions#update"
          delete "/:slug", to: "manage/polda/regions#destroy", as: :destroy_manage_polda_region
          scope "/:slug" do
            scope "staf" do
              # get "/", to: "manage/polda/staffs#index", as: :index_manage_polda_staff
              get "buat", to: "manage/polda/staffs#new", as: :new_manage_polda_staff
              post "buat", to: "manage/polda/staffs#create", as: :create_manage_polda_staff
              # get "data", to: "manage/polda/staffs#data", as: :data_manage_polda_staff
              # get "/:slug", to: "manage/polda/staffs#show", as: :show_manage_polda_staff
              # get "/:slug/ubah", to: "manage/polda/staffs#edit", as: :edit_manage_polda_staff
              # patch "/:slug/ubah", to: "manage/polda/staffs#update"
              # put "/:slug/ubah", to: "manage/polda/staffs#update"
              # delete "/:slug", to: "manage/polda/staffs#destroy", as: :destroy_manage_polda_staff
            end
            scope "laporan" do
            end
          end
        end
      end

      match "/", to: redirect("/"), via: :all
    end

    scope "superadmin" do
      scope "kelola" do
        scope "operator" do
          get "/", to: "superadmin/promotes#index", as: :index_superadmin_promote
          get "tambah", to: "superadmin/promotes#new", as: :new_superadmin_promote
          post "tambah", to: "superadmin/promotes#promote_operator", as: :add_operator_superadmin_promote
          post "tambah-superadmin", to: "superadmin/promotes#promote_superadmin", as: :add_superadmin_superadmin_promote
          post "hapus-superadmin", to: "superadmin/promotes#demote_superadmin", as: :remove_superadmin_superadmin_promote
          get "hapus/:slug", to: "superadmin/promotes#demote_operator", as: :remove_operator_superadmin_promote
          post "cari", to: "superadmin/promotes#search", as: :search_superadmin_promote
          get "data", to: "superadmin/promotes#data", as: :data_superadmin_promote
          patch ":slug/toggle-status", to: "superadmin/promotes#toggle_operator_status", as: :toggle_status_superadmin_promote
          patch ":slug/work-schedule", to: "superadmin/promotes#update_work_schedule", as: :update_schedule_superadmin_promote
        end

        scope "pengguna" do
          get "tambah", to: "superadmin/users#new", as: :new_superadmin_user
          post "tambah", to: "superadmin/users#create"
          match "/", to: redirect("/"), via: :all
        end

        scope "peserta" do
          get "tambah", to: "superadmin/participants#new", as: :new_superadmin_participant
          post "tambah", to: "superadmin/participants#mass_register"
          match "/", to: redirect("/"), via: :all
        end

        scope "borang" do
          get "cari", to: "superadmin/forms#search", as: :search_superadmin_forms
          post "data", to: "superadmin/forms#data"
          match "/", to: redirect("/"), via: :all
        end
        match "/", to: redirect("/"), via: :all
      end
      match "/", to: redirect("/"), via: :all
    end

    scope "polda" do
      scope "profil" do
        get "/", to: "module/polda/profiles#edit", as: :edit_module_polda_staff_profile
        patch "/", to: "module/polda/profiles#update"
        put "/", to: "module/polda/profiles#update"
      end

      match "/", to: redirect("/"), via: :all
    end
  end
end
