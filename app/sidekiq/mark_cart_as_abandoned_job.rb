class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform
    Rails.logger.info 'Marking cart as abandoned'
    Carts::MarkAbandonedService.call
    Rails.logger.info 'Cart marked as abandoned'
  end
end
