require 'rails_helper'

RSpec.describe Cart, type: :model do
  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart.valid?).to be_falsey
      expect(cart.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe 'scopes' do
    it 'active returns carts with status active' do
      create(:cart, status: 'active')
      create(:cart, status: 'abandoned')
      create(:cart, status: 'deleted')
      expect(Cart.active.count).to eq(1)
    end

    it 'abandoned returns carts with status abandoned' do
      create(:cart, status: 'active')
      create(:cart, status: 'abandoned')
      create(:cart, status: 'deleted')
      expect(Cart.abandoned.count).to eq(1)
    end

    it 'not_deleted excludes carts with status deleted' do
      create(:cart, status: 'active')
      create(:cart, status: 'abandoned')
      create(:cart, status: 'deleted')
      expect(Cart.not_deleted.count).to eq(2)
    end
  end

  describe '#mark_as_abandoned!' do
    it 'changes status from active to abandoned' do
      cart = create(:cart, status: 'active')
      cart.mark_as_abandoned!
      expect(cart.reload.status).to eq('abandoned')
    end

    it 'persists the change' do
      cart = create(:cart, status: 'active')
      cart.mark_as_abandoned!
      expect(Cart.abandoned.find(cart.id)).to eq(cart)
    end

    it 'keeps status abandoned when already abandoned' do
      cart = create(:cart, status: 'abandoned')
      cart.mark_as_abandoned!
      expect(cart.reload.status).to eq('abandoned')
    end
  end

  describe '#record_interaction!' do
    it 'updates last_interaction_at to current time' do
      cart = create(:cart, last_interaction_at: 2.days.ago)
      before_time = Time.current
      cart.record_interaction!
      after_time = Time.current
      expect(cart.reload.last_interaction_at).to be_between(before_time, after_time)
    end

    it 'changes status from abandoned to active when cart is abandoned' do
      cart = create(:cart, status: 'abandoned')
      cart.record_interaction!
      expect(cart.reload.status).to eq('active')
    end

    it 'keeps status active when cart is already active' do
      cart = create(:cart, status: 'active')
      cart.record_interaction!
      expect(cart.reload.status).to eq('active')
    end
  end

  describe 'remove_if_abandoned' do
    let(:shopping_cart) { create(:cart, last_interaction_at: 7.days.ago) }

    it 'removes the shopping cart if abandoned for a certain time' do
      shopping_cart.mark_as_abandoned!
      expect { shopping_cart.remove_if_abandoned }.to change { Cart.not_deleted.count }.by(-1)
    end
  end

  describe 'associations' do
    it 'has many cart_products' do
      cart = described_class.new
      expect(cart.cart_products).to be_a(ActiveRecord::Relation)
    end

    it 'has many products' do
      cart = described_class.new
      expect(cart.products).to be_a(ActiveRecord::Relation)
    end
  end

  describe 'should set default numerical value to total_price' do
    it 'on creation' do
      cart = described_class.create
      expect(cart.total_price).to eq(0)
    end
  end
end
