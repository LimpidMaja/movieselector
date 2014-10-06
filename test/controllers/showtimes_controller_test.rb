require 'test_helper'

class ShowtimesControllerTest < ActionController::TestCase
  setup do
    @showtime = showtimes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:showtimes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create showtime" do
    assert_difference('Showtime.count') do
      post :create, showtime: { cinema: @showtime.cinema, city: @showtime.city, country: @showtime.country, date: @showtime.date, is_3d: @showtime.is_3d, is_synchronized: @showtime.is_synchronized, movie_id: @showtime.movie_id, original_title: @showtime.original_title, state: @showtime.state, time: @showtime.time, title: @showtime.title }
    end

    assert_redirected_to showtime_path(assigns(:showtime))
  end

  test "should show showtime" do
    get :show, id: @showtime
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @showtime
    assert_response :success
  end

  test "should update showtime" do
    patch :update, id: @showtime, showtime: { cinema: @showtime.cinema, city: @showtime.city, country: @showtime.country, date: @showtime.date, is_3d: @showtime.is_3d, is_synchronized: @showtime.is_synchronized, movie_id: @showtime.movie_id, original_title: @showtime.original_title, state: @showtime.state, time: @showtime.time, title: @showtime.title }
    assert_redirected_to showtime_path(assigns(:showtime))
  end

  test "should destroy showtime" do
    assert_difference('Showtime.count', -1) do
      delete :destroy, id: @showtime
    end

    assert_redirected_to showtimes_path
  end
end
