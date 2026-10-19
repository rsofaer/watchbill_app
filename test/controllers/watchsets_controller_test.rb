require "test_helper"

class WatchsetsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get watchsets_url
    assert_response :success
  end
end
