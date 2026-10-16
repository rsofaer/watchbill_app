require "test_helper"

class WatchsetControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get watchset_index_url
    assert_response :success
  end

  test "should get show" do
    get watchset_show_url
    assert_response :success
  end
end
