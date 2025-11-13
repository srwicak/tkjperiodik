require "test_helper"

class Module::Polda::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get module_polda_profiles_edit_url
    assert_response :success
  end

  test "should get update" do
    get module_polda_profiles_update_url
    assert_response :success
  end
end
