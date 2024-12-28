require 'rails_helper'

RSpec.describe Company, type: :model do
  describe 'associations' do
    it { should have_many(:addresses).dependent(:destroy) }
    it { should accept_nested_attributes_for(:addresses) }
  end

  describe 'validations' do
    subject { build(:company) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(256) }
    it { should validate_presence_of(:registration_number) }
    it { should validate_uniqueness_of(:registration_number) }
    it { should validate_numericality_of(:registration_number).only_integer }
  end

  describe 'instance' do
    it 'is valid with proper attributes' do
      expect(build(:company)).to be_valid
    end

    it 'is invalid with bad attributes' do
      expect(Company.new(name: '', registration_number: 'ThisIsBad')).to be_invalid
    end
  end
end
