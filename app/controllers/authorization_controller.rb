class AuthorizationController < ApplicationController
  # Users are redirected here, on your app's domain by the cloudfront error page.
  # If they are logged in then we create a ticket for them and redirect them to the set_cookies action
  #
  # We assume all users can access any content - in the real world you might want to check some property of the
  # user before issuing the tickets
  def get_ticket
    if current_user
      ticket = current_user.tickets.create! service: params[:service]
      redirect_to set_cookies_url(:ticket => ticket.token, :host => URI.parse(params[:service]).host)
    else
      store_location_for(:user, get_ticket_path(service: params[:service]))
      redirect_to new_user_session_path
    end
  end

  # This action is always accessed via the cloudfront distribution. it verifies the ticket passed
  # and if valid it sets the cloudfront cookies and redirects to the location  originally requested
  #
  # Tickets are destroyed after use.
  #
  def set_cookies
    ticket = Ticket.find_by(token: params[:ticket])
    if ticket && URI.parse(ticket.service).host
      CloudfrontSigner.cookie_data("http*://#{URI.parse(ticket.service).host}/*", 2.hour.from_now).each do |name, value|
        cookies[name] = {:value => value, :httponly => true}
      end
      redirect_to ticket.service
      ticket.destroy!
    end
  end

  private
end
