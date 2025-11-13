class UserVerificationChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    stream_from "user_verification_channel"
  end

  def unsubscribed
    # Rails.logger.info "UserVerificationChannel disconnected"
    # Any cleanup needed when channel is unsubscribed
  end
end
