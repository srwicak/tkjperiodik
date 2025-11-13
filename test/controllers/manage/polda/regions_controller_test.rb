require "test_helper"

class Manage::Polda::RegionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get manage_polda_regions_index_url
    assert_response :success
  end

  test "should get new" do
    get manage_polda_regions_new_url
    assert_response :success
  end

  test "should get create" do
    get manage_polda_regions_create_url
    assert_response :success
  end

  test "should get edit" do
    get manage_polda_regions_edit_url
    assert_response :success
  end

  test "should get update" do
    get manage_polda_regions_update_url
    assert_response :success
  end

  test "should get destroy" do
    get manage_polda_regions_destroy_url
    assert_response :success
  end
end
