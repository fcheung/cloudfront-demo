require 'test_helper'

class AuthorizationControllerTest < ActionController::TestCase

  test "get_ticket redirects unlogged in users to the login page" do
    get :get_ticket, service: 'http://example.com/index.html'
    assert_redirected_to new_user_session_path
    assert_equal get_ticket_path(service:'http://example.com/index.html'), @controller.stored_location_for(:user)
  end

  test "get_ticket redirects logged in users to the service url with a new ticket" do
    user = User.create!(email: 'bob@example.com', password: 'password', password_confirmation: 'password')
    sign_in user
    assert_difference -> {Ticket.count} do
      get :get_ticket, service: 'http://example.com/index.html'
    end
    assert_redirected_to "http://example.com/authorization/set_cookies?ticket=#{user.tickets.last.token}"
    assert_equal "http://example.com/index.html", Ticket.last.service
  end

  test "set_cookies with a valid token should set cookies & redirect" do
    user = User.create!(email: 'bob@example.com', password: 'password', password_confirmation: 'password')
    ticket = user.tickets.create! service: 'http://test.host/foo'
    assert_difference -> {Ticket.count}, -1 do
      get :set_cookies, :ticket => ticket.token
    end
    assert_not_nil cookies['CloudFront-Policy']
    assert_not_nil cookies['CloudFront-Signature']
    assert_not_nil cookies['CloudFront-Key-Pair-Id']
    assert_redirected_to "http://test.host/foo"
  end

  test "set_cookies with a token valid for a different host should not set cookies" do
    user = User.create!(email: 'bob@example.com', password: 'password', password_confirmation: 'password')
    ticket = user.tickets.create! service: 'http://example.com/foo'
    get :set_cookies, :ticket => ticket.token
    
    assert_nil cookies['CloudFront-Policy']
    assert_nil cookies['CloudFront-Signature']
    assert_nil cookies['CloudFront-Key-Pair-Id']
  end

  test "set_cookies with an invalid token should not set cookies" do
    get :set_cookies, :ticket => 'invalid'
    assert_nil cookies['CloudFront-Policy']
    assert_nil cookies['CloudFront-Signature']
    assert_nil cookies['CloudFront-Key-Pair-Id']
  end
end
