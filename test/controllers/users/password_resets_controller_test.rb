require "test_helper"

class Users::PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get users_password_resets_new_url
    assert_response :success
  end

  test "should get create" do
    get users_password_resets_create_url
    assert_response :success
  end

  test "should get edit" do
    get users_password_resets_edit_url
    assert_response :success
  end

  test "should get update" do
    get users_password_resets_update_url
    assert_response :success
  end
end
