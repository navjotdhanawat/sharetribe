class StripeCancelDepositJob < Struct.new(:transaction_id, :community_id)

  include DelayedAirbrakeNotification

  # This before hook should be included in all Jobs to make sure that the service_name is
  # correct as it's stored in the thread and the same thread handles many different communities
  # if the job doesn't have host parameter, should call the method with nil, to set the default service_name
  def before(job)
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(community_id)
  end

  def perform
    tx = TransactionService::Transaction.query transaction_id
    result = StripeService::API::Api.payments.cancel_deposit(tx, nil)
    if result.success
      unless result.data.is_a?(String)
        tx_model = ::Transaction.find(transaction_id)
        message = Message.new(
          conversation_id: tx_model.conversation_id, 
          sender_id: tx_model.listing_author_id,
          content: "Automatically refunded deposit of " + MoneyViewUtils.to_humanized(result.data[:refund_amount]))
        message.save
        Delayed::Job.enqueue(MessageSentJob.new(message.id, community_id))
      end
    end
  end
end
