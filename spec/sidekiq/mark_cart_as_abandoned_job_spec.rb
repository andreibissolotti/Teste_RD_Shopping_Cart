require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  describe '#perform' do
    it 'calls Carts::MarkAbandonedService' do
      allow(Carts::MarkAbandonedService).to receive(:call).and_return(marked_count: 2)

      described_class.new.perform

      expect(Carts::MarkAbandonedService).to have_received(:call)
    end

    it 'marks inactive carts as abandoned' do
      cart = create(:cart, status: 'active', last_interaction_at: 4.hours.ago)

      described_class.new.perform

      expect(cart.reload.status).to eq('abandoned')
    end
  end
end
