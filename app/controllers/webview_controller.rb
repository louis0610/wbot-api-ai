# frozen_string_literal: true
# Facebook webview
class WebviewController < ApplicationController
  skip_before_action :verify_authenticity_token

  def locations
    @locations = KnownLocation.where(type: 'location').map { |kl| kl.name.capitalize }
    render layout: false
  end

  def reply_to_location
    return if params[:location].blank? || params[:uid].blank?
    request_message = params[:location]
    uid = params[:uid]
    user = User.where(uid: uid).first || User.create(uid: uid, source: 'facebook')

    Message.create(body: request_message, user: user, kind: 'incoming')

    puts "[debuz] got from Facebook WEBVIEW... #{request_message}"
    chat_service = ChatService.new(uid)
    chat_service.execute(request_message)
    FacebookMessengerService.deliver(uid, chat_service.response_message, chat_service.quick_replies, chat_service.response_template)
    FacebookMessengerService.deliver(uid, chat_service.follow_up_response_message, chat_service.quick_replies) if chat_service.follow_up_response_message.present?
  end
end
