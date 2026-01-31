require 'rails_helper'

RSpec.describe DeleteOldAbandonedCartsJob, type: :job do
  describe '#perform' do
    it 'calls Carts::DeleteOldAbandonedService' do
      allow(Carts::DeleteOldAbandonedService).to receive(:call).and_return(deleted_count: 0, mode: 'soft')

      described_class.new.perform

      expect(Carts::DeleteOldAbandonedService).to have_received(:call)
    end

    context 'when abandoned carts are older than 7 days' do
      around do |example|
        previous = ENV['CART_DELETION_MODE']
        ENV['CART_DELETION_MODE'] = 'soft'
        example.run
        ENV['CART_DELETION_MODE'] = previous
      end

      it 'deletes them via the service' do
        cart = create(:cart, status: 'abandoned')
        cart.update_columns(updated_at: 8.days.ago)

        described_class.new.perform

        expect(cart.reload.status).to eq('deleted')
      end
    end
  end
end
