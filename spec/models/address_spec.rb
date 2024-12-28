require 'rails_helper'

RSpec.describe Address, type: :model do
  describe 'associations' do
    it { should belong_to(:company) }
  end

  describe 'validations' do
    it { should validate_presence_of(:street) }
    it { should validate_presence_of(:city) }
    it { should validate_presence_of(:country) }
  end

  describe 'instance' do
    it 'is valid with proper attributes' do
      expect(build(:address)).to be_valid
    end

    it 'is invalid with bad attributes' do
      expect(Address.new(street: '', postal_code: '12-452')).to be_invalid
    end
  end
end
