class TimeController < ApplicationController
  def current
    render json: { server_time: Time.now.in_time_zone('Asia/Jakarta').to_s }
  end
end
