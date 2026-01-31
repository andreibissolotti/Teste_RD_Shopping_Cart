module Carts
  class MarkAbandonedService
    INACTIVITY_THRESHOLD = ENV.fetch('INACTIVITY_THRESHOLD', 3).to_i.hours

    def self.call(threshold: INACTIVITY_THRESHOLD)
      new.call(threshold: threshold)
    end

    def call(threshold: INACTIVITY_THRESHOLD)
      cutoff = threshold.ago
      carts_to_mark = Cart.active.where(
        'last_interaction_at < ? OR (last_interaction_at IS NULL AND updated_at < ?)',
        cutoff,
        cutoff
      )

      marked_count = 0
      carts_to_mark.find_each do |cart|
        cart.mark_as_abandoned!
        marked_count += 1
      end

      { marked_count: marked_count }
    end
  end
end
