class Geodeliver < ActiveRecord::Base
	belongs_to :user

def build_index #creates uniq geodeliver for all users
raw = []
det_ip = "65.95.161.221"
User.all.includes(:geodeliver).each do |x|

puts x
if Geodeliver.all.where(user_id: x.id).count == 0
puts "create geodeliver index"

country_index = 0
postal_index = 0
country_code = ""
postal_code = ""

testip = Geocoder.search("#{det_ip}")
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
sleep 5

else
puts "user already indexed"
end

end
end #end build_index


end
