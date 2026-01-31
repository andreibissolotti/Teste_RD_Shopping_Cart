class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform
    Carts::MarkAbandonedService.call
  end
end
