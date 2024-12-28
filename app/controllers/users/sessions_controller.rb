class Users::SessionsController < Devise::SessionsController
  include RackSessionFix

  def create
    user = warden.authenticate!(auth_options)
    token = Tiddle.create_and_return_token(user, request, expires_in: 1.week)
    render json: { message: "Authenticated", authentication_token: token }
  end

  def destroy
    Tiddle.expire_token(current_user, request) if current_user
    render json: { message: "Session deleted." }
  end

  private

  # this is invoked before destroy and we have to override it
  def verify_signed_out_user
  end
end
