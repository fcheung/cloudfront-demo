class AuthorizationController < ApplicationController
  def get_ticket
    if current_user
      ticket = current_user.tickets.create! service: params[:service]
      redirect_to set_cookies_url(:ticket => ticket.token, :host => URI.parse(params[:service]).host)
    else
      store_location_for(:user, get_ticket_path)
      redirect_to new_user_session_path
    end
  end

  def set_cookies
    ticket = Ticket.find_by(token: params[:ticket])
    if ticket && request.host == URI.parse(ticket.service).host
      CloudfrontSigner.cookie_data("http*://#{request.host}/*", 1.hour.from_now).each do |name, value|
        cookies[name] = value
      end
      redirect_to ticket.service
      ticket.destroy!
    end
  end

  private
end
