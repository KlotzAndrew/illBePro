FactoryGirl.define do

  factory :user do
    email 'test@illbepro.com'
    password 'password'
    password_confirmation 'password'
  end

  trait :with_ignindex do
    after :create do |user|
      FactoryGirl.create_list :ignindex, 1, :user => user
    end
  end

end