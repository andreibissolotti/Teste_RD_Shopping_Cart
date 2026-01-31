module Carts
  class DeleteOldAbandonedService
    CART_DELETION_THRESHOLD_DAYS = ENV.fetch('CART_DELETION_THRESHOLD_DAYS', 7).to_i.days

    def self.call(older_than: CART_DELETION_THRESHOLD_DAYS)
      new.call(older_than: older_than)
    end

    def call(older_than: CART_DELETION_THRESHOLD_DAYS)
      cutoff = older_than.ago
      carts_to_delete = Cart.abandoned.where('updated_at < ?', cutoff)
      mode = deletion_mode

      deleted_count = 0
      carts_to_delete.find_each do |cart|
        success = cart.delete_cart(mode: mode)
        deleted_count += 1 if success
      end

      { deleted_count: deleted_count, mode: mode }
    end

    private

    def deletion_mode
      ENV.fetch('CART_DELETION_MODE', 'soft').to_s.downcase
    end
  end
end
