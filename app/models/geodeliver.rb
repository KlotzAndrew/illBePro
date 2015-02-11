class Geodeliver < ActiveRecord::Base
	belongs_to :user

def self.build_index #creates uniq geodeliver for all users
raw = []
User.all.includes(:geodeliver).each do |x|

Rails.logger.info "#{x}"
if x.last_sign_in_ip.nil?
	Rails.logger.info  "not signed in yet"
elsif Geodeliver.all.where(user_id: x.id).count == 0
Rails.logger.info  "create geodeliver index"

country_index = 0
postal_index = 0
country_code = ""
postal_code = ""

testip = Geocoder.search("#{x.last_sign_in_ip}")
testlock = Geocoder.search("#{testip[0].latitude}, #{testip[0].longitude}")
raw << testlock
country_index = testlock[0].address_components.index{ |x| x["types"][0]=="country"}
if testlock[0].address_components[country_index]["short_name"] == "US"
  postal_index = testlock[0].address_components.index{ |x| x["types"][0]=="postal_code" or x["types"][1]=="postal_code"}
  postal_code = testlock[0].address_components[postal_index]["long_name"]
  country_code = "US"
elsif testlock[0].address_components[country_index]["short_name"] == "CA"
  postal_index = testlock[0].address_components.index{ |x| x["types"][0]=="postal_code" or x["types"][1]=="postal_code"}
  postal_code = testlock[0].address_components[postal_index]["long_name"]
  country_code = "CA"
else
	postal_code = ""
  country_code = testlock[0].address_components[country_index]["short_name"]
end

Geodeliver.create(
	:user_id => x.id, 
	:ip_address => x.last_sign_in_ip, 
	:latitude => testip[0].latitude,
	:longitude => testip[0].longitude,
	:country_code => country_code,
	:postal_code => postal_code)
Rails.logger.info "#{Geodeliver.last.postal_code}" 
Geodeliver.last.postal_code "#{Geodeliver.last.id}" 
Rails.logger.info  "sleeping for 42s"
sleep 42

else
Rails.logger.info  "user already indexed"
end

end
end #end build_index


end
