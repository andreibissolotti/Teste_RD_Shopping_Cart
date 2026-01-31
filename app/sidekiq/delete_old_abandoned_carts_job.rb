class DeleteOldAbandonedCartsJob
  include Sidekiq::Job

  def perform
    Carts::DeleteOldAbandonedService.call
  end
end
