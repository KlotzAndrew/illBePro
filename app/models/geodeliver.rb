class Geodeliver < ActiveRecord::Base
	belongs_to :user

	def valid_location2
		if self.country_code == "US"
			if self.postal_code.length > 5
				self.update(postal_code: self.postal_code[0..4])
			end
			valid_region = Region.where("country = ?", "US").where("postal_code = ?", self.postal_code)
			if valid_region.count > 0
				self.update(address: "0")
				self.update(region_id: valid_region.first.id)
			else
				self.update(address: "1") #no service
			end
		elsif self.country_code == "CA"
			if self.postal_code.length > 3
				self.update(postal_code: self.postal_code[0..2])
			end
			self.update(postal_code: self.postal_code.upcase)
			valid_region = Region.where("country = ?", "CA").where("postal_code = ?", self.postal_code)
			if valid_region.count > 0
				self.update(address: "0")
				self.update(region_id: valid_region.first.id)
			else
				self.update(address: "1") #no service
			end
		else
			self.update(address: "2") #no country
		end

	end
	

	def valid_location
		if self.country_code == "US"
			if ((self.postal_code =~ /\d{5}/) == 0) && (self.postal_code.length == 5)
				if Region.where("postal_code == ?", self.postal_code).count > 0
					self.update(address: "0")
					self.update(region_id: Region.where("postal_code == ?", self.postal_code).first.id)
				else
					self.update(address: "2") #no service
				end
			else
				self.update(address: "1") #format wrong
			end
		elsif self.country_code == "CA"
			if ((self.postal_code =~ /\d{5}/) == 0) && (self.postal_code.length == 5)
				if Region.where("postal_code == ?", self.postal_code).count > 0
					self.update(address: "0")
				else
					self.update(address: "2") #no service
				end
			else
				self.update(address: "1") #format wrong
			end

		else
			self.update(address: "2")
		end
	end

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

			begin
				testip = Geocoder.search("#{x.last_sign_in_ip}")
		    rescue Timeout::Error
		        Rails.logger.info "URI-TIMEOUT request for 1st part"
		    rescue => e
		        Rails.logger.info "uri error request for 1st parts"
		    end

		    begin
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
				Rails.logger.info "#{Geodeliver.last.id}" 
				Rails.logger.info  "sleeping for 42s"
				sleep 55
			rescue Timeout::Error
		        Rails.logger.info "URI-TIMEOUT request for 2nd part"
		    rescue => e
		        Rails.logger.info "uri error request for 2nd part"
		    end

		else
		Rails.logger.info  "user already indexed"
		end

		end
	end #end build_index


end
