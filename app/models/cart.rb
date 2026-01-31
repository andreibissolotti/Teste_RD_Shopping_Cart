class Cart < ApplicationRecord

  validates_numericality_of :total_price, greater_than_or_equal_to: 0
  has_many :cart_products, dependent: :destroy
  has_many :products, through: :cart_products

  scope :active, -> { where(status: 'active') }
  scope :abandoned, -> { where(status: 'abandoned') }
  scope :not_deleted, -> { where.not(status: 'deleted') }

  before_validation :set_default_total_price, on: :create

  def record_interaction!
    self.last_interaction_at = Time.current
    self.status = 'active' if status == 'abandoned'
    save!
  end

  def mark_as_abandoned!
    self.status = 'abandoned'
    save!
  end

  def delete_cart(mode: 'soft')
    return false unless status == 'abandoned'
    delete!(mode)
    true
  rescue ActiveRecord::RecordNotDestroyed
    false
  end

  private

  def set_default_total_price
    self.total_price ||= 0
  end

  def delete!(mode)
    if mode == 'hard'
      destroy!
    else
      self.status = 'deleted'
      save!
    end
  end
end
