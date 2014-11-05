require 'test_helper'

class IgnindicesControllerTest < ActionController::TestCase
  setup do
    @ignindex = ignindices(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:ignindices)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create ignindex" do
    assert_difference('Ignindex.count') do
      post :create, ignindex: { owner_id: @ignindex.owner_id, summoner_id: @ignindex.summoner_id, summoner_name: @ignindex.summoner_name, summoner_validated: @ignindex.summoner_validated, validation_string: @ignindex.validation_string, validation_timer: @ignindex.validation_timer }
    end

    assert_redirected_to ignindex_path(assigns(:ignindex))
  end

  test "should show ignindex" do
    get :show, id: @ignindex
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @ignindex
    assert_response :success
  end

  test "should update ignindex" do
    patch :update, id: @ignindex, ignindex: { owner_id: @ignindex.owner_id, summoner_id: @ignindex.summoner_id, summoner_name: @ignindex.summoner_name, summoner_validated: @ignindex.summoner_validated, validation_string: @ignindex.validation_string, validation_timer: @ignindex.validation_timer }
    assert_redirected_to ignindex_path(assigns(:ignindex))
  end

  test "should destroy ignindex" do
    assert_difference('Ignindex.count', -1) do
      delete :destroy, id: @ignindex
    end

    assert_redirected_to ignindices_path
  end
end
