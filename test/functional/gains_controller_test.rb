require File.dirname(__FILE__) + '/../test_helper'
require 'gains_controller'

# Re-raise errors caught by the controller.
class GainsController; def rescue_action(e) raise e end; end

class GainsControllerTest < Test::Unit::TestCase
  fixtures :gains

  def setup
    @controller = GainsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:gains)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:gain)
    assert assigns(:gain).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:gain)
  end

  def test_create
    num_gains = Gain.count

    post :create, :gain => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_gains + 1, Gain.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:gain)
    assert assigns(:gain).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil Gain.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Gain.find(1)
    }
  end
end
