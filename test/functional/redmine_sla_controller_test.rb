require 'test_helper'

class RedmineSLAControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  def test_index
    get :index
    assert_response :success
  end
end
