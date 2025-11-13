# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Configuration
example_police_count = 25
example_staff_count = 10

# The magic happens here, xoxo :D
# The seeds only worked in development
if Rails.env.development?
  puts "Seed initialization for TKJ PERIODIK+"
  puts "==========================================================="

  print "Are you sure you want to delete all data before seeding? (y[es]/n[o]/a[dd]): "
  confirmation = gets.chomp.downcase

  # Asking for confirmation
  if confirmation == "y"
    puts "Deleting all records"
    User.destroy_all
    puts "All records deleted"
    puts "========================================================="
    puts "Creating SuperAdmin"
    superadmin = User.new(identity: "00000000", password: "GiHjRBLwOpwBMI1", is_verified: true, is_onboarded: true, account_status: :active)
    superadmin.save(validate: false)
    puts "Seed SuperAdmin created"

    if superadmin.persisted?
      UserDetail.find_or_create_by(user: superadmin) do |user_detail|
        user_detail.name = "Superadmin"
        user_detail.rank = 14
        user_detail.unit = (0...24).to_a.sample
        user_detail.position = "Superadmin"
        user_detail.gender = true
        user_detail.is_operator_granted = true
        user_detail.is_superadmin_granted = true
      end
      puts "UserDetail for SuperAdmin created or found"
    else
      puts "Failed to create UserDetail: User creation failed"
    end
  elsif confirmation == "a"
    puts "========================================================="
    puts "Creating Example Police User"
    print "Example police: "
    police_ids = []

    # Create example police users with total of example_police_count
    example_police_count.times do |index|
      print "#{index + 1} "
      id = Faker::Number.number(digits: 8)
      police_ids << id

      police = User.new(
        identity: id,
        password: "password",
        is_verified: [true, false].sample,
        is_onboarded: [true, false].sample,
        account_status: [0, 1, 2].sample,
      )
      police.save(validate: false)

      if police.is_verified? && police.active?
        UserDetail.find_or_create_by(user: police) do |user_detail|
          user_detail.name = Faker::Name.name
          user_detail.rank = (0...14).to_a.sample
          user_detail.unit = (0...24).to_a.sample
          user_detail.position = "POLISI"
          user_detail.gender = [true, false].sample
          user_detail.is_operator_granted = [true, false].sample
          user_detail.is_superadmin_granted = [true, false].sample
        end
      end
    end

    print "\n"

    # Write example police ids to db/example_police_ids.txt
    File.open("db/example_police_ids.txt", "w") do |f|
      f.write("Police IDs:\n")
      f.write("All passwords: password\n\n")
      f.write(police_ids.join("\n"))
    end

    puts "Example Police IDs written to db/example_police_ids.txt"
    puts "========================================================="

    puts "Creating Example Staff User"
    print "Example staff: "
    staff_ids = []

    # Create example staff users with total of example_staff_count
    example_staff_count.times do |index|
      print "#{index + 1} "
      id = Faker::Number.number(digits: 18)
      staff_ids << id

      staff = User.new(
        identity: id,
        password: "password",
        is_verified: [true, false].sample,
        is_onboarded: [true, false].sample,
        account_status: [0, 1, 2].sample,
      )
      staff.save(validate: false)

      if staff.is_verified? && staff.active?
        UserDetail.find_or_create_by(user: staff) do |user_detail|
          user_detail.name = Faker::Name.name
          user_detail.gender = [true, false].sample
          user_detail.is_operator_granted = [true, false].sample
          user_detail.is_superadmin_granted = [true, false].sample
        end
      end
    end

    print "\n"

    # Write example staff ids to db/example_seed_staff_ids.txt
    File.open("db/example_staff_ids.txt", "w") do |f|
      f.write("Staff IDs:\n")
      f.write("All passwords: password\n\n")
      f.write(staff_ids.join("\n"))
    end
    puts "Example Staff IDs written to db/example_staff_ids.txt"
  else
    puts "Seeding cancelled"
    return
  end
end
