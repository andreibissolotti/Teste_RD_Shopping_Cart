require 'rails_helper'

RSpec.describe Carts::DeleteOldAbandonedService do
  describe '.call' do
    context 'when CART_DELETION_MODE is soft (default)' do
      around do |example|
        previous = ENV['CART_DELETION_MODE']
        ENV['CART_DELETION_MODE'] = 'soft'
        example.run
        ENV['CART_DELETION_MODE'] = previous
      end

      context 'when abandoned carts have updated_at older than 7 days' do
        let!(:cart1) { create(:cart, status: 'abandoned') }
        let!(:cart2) { create(:cart, status: 'abandoned') }

        before do
          cart1.update_columns(updated_at: 8.days.ago)
          cart2.update_columns(updated_at: 10.days.ago)
        end

        it 'updates status to deleted' do
          result = described_class.call

          expect(cart1.reload.status).to eq('deleted')
          expect(cart2.reload.status).to eq('deleted')
          expect(result[:deleted_count]).to eq(2)
          expect(result[:mode]).to eq('soft')
          expect(Cart.not_deleted.count).to eq(0)
        end

        it 'does not destroy the records' do
          expect { described_class.call }.not_to change(Cart, :count)
        end
      end
    end

    context 'when CART_DELETION_MODE is hard' do
      around do |example|
        previous = ENV['CART_DELETION_MODE']
        ENV['CART_DELETION_MODE'] = 'hard'
        example.run
        ENV['CART_DELETION_MODE'] = previous
      end

      context 'when abandoned carts have updated_at older than 7 days' do
        let!(:cart1) { create(:cart, status: 'abandoned') }

        before do
          cart1.update_columns(updated_at: 8.days.ago)
        end

        it 'destroys the carts' do
          result = described_class.call

          expect(Cart.exists?(cart1.id)).to be false
          expect(result[:deleted_count]).to eq(1)
          expect(result[:mode]).to eq('hard')
        end

        it 'returns deleted_count and mode' do
          result = described_class.call

          expect(result).to eq(deleted_count: 1, mode: 'hard')
        end
      end
    end

    context 'when abandoned cart has updated_at within 7 days' do
      let!(:cart) { create(:cart, status: 'abandoned') }

      before do
        cart.update_columns(updated_at: 5.days.ago)
      end

      it 'does not delete it' do
        result = described_class.call

        expect(cart.reload.status).to eq('abandoned')
        expect(result[:deleted_count]).to eq(0)
      end
    end

    context 'when no abandoned carts match' do
      it 'returns deleted_count 0' do
        result = described_class.call

        expect(result[:deleted_count]).to eq(0)
        expect(result[:mode]).to eq('soft')
      end
    end

    context 'when ENV is not set' do
      around do |example|
        previous = ENV['CART_DELETION_MODE']
        ENV.delete('CART_DELETION_MODE')
        example.run
        ENV['CART_DELETION_MODE'] = previous
      end

      it 'defaults to soft mode' do
        cart = create(:cart, status: 'abandoned')
        cart.update_columns(updated_at: 8.days.ago)

        result = described_class.call

        expect(result[:mode]).to eq('soft')
        expect(cart.reload.status).to eq('deleted')
      end
    end

    context 'with custom older_than threshold' do
      around do |example|
        previous = ENV['CART_DELETION_MODE']
        ENV['CART_DELETION_MODE'] = 'soft'
        example.run
        ENV['CART_DELETION_MODE'] = previous
      end

      it 'uses the provided threshold' do
        cart = create(:cart, status: 'abandoned')
        cart.update_columns(updated_at: 3.days.ago)

        result = described_class.call(older_than: 2.days)

        expect(cart.reload.status).to eq('deleted')
        expect(result[:deleted_count]).to eq(1)
      end
    end
  end
end
