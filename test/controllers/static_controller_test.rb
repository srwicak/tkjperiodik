require "test_helper"

class StaticControllerTest < ActionDispatch::IntegrationTest
  test "should get waiting" do
    get static_waiting_url
    assert_response :success
  end
end
