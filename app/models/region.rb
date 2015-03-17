class Region < ActiveRecord::Base

has_many :prizes

  def self.import_data
    zip.each do |x|
      Region.create(
        :postal_code => x["zip"].to_s,
        :city => x["city"],
        :lat => x["latitude"],
        :long => x["longitude"],
        :country => x["Country"],
        :province => x["province"] )
    end
  end

end
