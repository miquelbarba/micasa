require 'test_helper'

class FlatControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get flat_index_url
    assert_response :success
  end

end
