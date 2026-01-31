require 'rails_helper'

RSpec.describe Carts::MarkAbandonedService do
  describe '.call' do
    context 'when active carts have no interaction in the last 3 hours' do
      before do
        create(:cart, status: 'active', last_interaction_at: 4.hours.ago)
        create(:cart, status: 'active', last_interaction_at: 5.hours.ago)
      end

      it 'marks them as abandoned' do
        result = described_class.call

        expect(Cart.abandoned.count).to eq(2)
        expect(Cart.active.count).to eq(0)
        expect(result[:marked_count]).to eq(2)
      end

      it 'returns marked_count' do
        result = described_class.call

        expect(result).to eq(marked_count: 2)
      end
    end

    context 'when active cart has last_interaction_at nil and updated_at older than 3 hours' do
      let!(:cart) { create(:cart, status: 'active', last_interaction_at: nil) }

      before do
        cart.update_columns(updated_at: 4.hours.ago)
      end

      it 'marks it as abandoned' do
        result = described_class.call

        expect(cart.reload.status).to eq('abandoned')
        expect(result[:marked_count]).to eq(1)
      end
    end

    context 'when active cart has recent interaction' do
      before do
        create(:cart, status: 'active', last_interaction_at: 1.hour.ago)
      end

      it 'does not mark it as abandoned' do
        result = described_class.call

        expect(Cart.active.count).to eq(1)
        expect(Cart.abandoned.count).to eq(0)
        expect(result[:marked_count]).to eq(0)
      end
    end

    context 'when cart is already abandoned' do
      before do
        create(:cart, status: 'abandoned', last_interaction_at: 5.hours.ago)
      end

      it 'does not change it and does not count it' do
        result = described_class.call

        expect(Cart.abandoned.count).to eq(1)
        expect(result[:marked_count]).to eq(0)
      end
    end

    context 'when no carts match the condition' do
      it 'returns marked_count 0' do
        result = described_class.call

        expect(result[:marked_count]).to eq(0)
      end
    end

    context 'with custom threshold' do
      before do
        create(:cart, status: 'active', last_interaction_at: 2.hours.ago)
      end

      it 'uses the provided threshold' do
        result = described_class.call(threshold: 1.hour)

        expect(Cart.abandoned.count).to eq(1)
        expect(result[:marked_count]).to eq(1)
      end
    end
  end
end
