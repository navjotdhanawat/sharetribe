class TwilioSmsJob < Struct.new(:community_id, :user_id, :message)
  include DelayedAirbrakeNotification

  # This before hook should be included in all Jobs to make sure that the service_name is
  # correct as it's stored in the thread and the same thread handles many different communities
  # if the job doesn't have host parameter, should call the method with nil, to set the default service_name
  def before(job)
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(community_id)
  end

  def perform
    community   = Community.find(community_id)
    account_sid = APP_CONFIG.twilio_sid
    auth_token  = APP_CONFIG.twilio_token
    from        = APP_CONFIG.twilio_from
    client = Twilio::REST::Client.new account_sid, auth_token
    user = Person.where(id: user_id, community_id: community_id).first
    phone_number = (user && user.phone_number.present? ? user.phone_number : "").gsub(/[^0-9]/,'')
    if phone_number.present?
      client.messages.create({body: message, from: from, to: "+"+phone_number})
    end
  end
end
