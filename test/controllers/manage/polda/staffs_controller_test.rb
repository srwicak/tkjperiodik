require "test_helper"

class Manage::Polda::StaffsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get manage_polda_staffs_index_url
    assert_response :success
  end

  test "should get show" do
    get manage_polda_staffs_show_url
    assert_response :success
  end

  test "should get new" do
    get manage_polda_staffs_new_url
    assert_response :success
  end

  test "should get create" do
    get manage_polda_staffs_create_url
    assert_response :success
  end

  test "should get edit" do
    get manage_polda_staffs_edit_url
    assert_response :success
  end

  test "should get update" do
    get manage_polda_staffs_update_url
    assert_response :success
  end

  test "should get destroy" do
    get manage_polda_staffs_destroy_url
    assert_response :success
  end
end
