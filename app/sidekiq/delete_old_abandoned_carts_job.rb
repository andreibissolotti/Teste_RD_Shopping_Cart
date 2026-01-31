class DeleteOldAbandonedCartsJob
  include Sidekiq::Job

  def perform
    Rails.logger.info 'Deleting old abandoned carts'
    Carts::DeleteOldAbandonedService.call
    Rails.logger.info 'Old abandoned carts deleted'
  end
end
