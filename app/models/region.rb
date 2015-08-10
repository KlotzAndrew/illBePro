class Region < ActiveRecord::Base

has_many :prize_regions
has_many :prizes, through: :prize_regions

has_many :challenge_regions
has_many :challenges, :through => :challenge_regions


  def self.postal_to_region(postal_string)
    Rails.logger.info "postal_string: #{postal_string}"
    postal_search = postal_string.to_s
    Rails.logger.info "postal_search: #{postal_search}"
    if !/[0-9]/.match(postal_search[0]).nil? #this is a zip code
      postal_search = Region.tuncate_zip_code(postal_search)
    elsif !/[a-zA-Z]/.match(postal_search[0]).nil? #this is a postal code
      postal_search = Region.tuncate_postal_code(postal_search)
    end

    Rails.logger.info "postal_search: #{postal_search}"
    if !Region.where("postal_code = ?", postal_search).first.nil?
      return Region.where("postal_code = ?", postal_search).first
    end
  end  

  def self.tuncate_postal_code(postal_search)
    if postal_search.length >= 3
      return postal_search[0..2].upcase
    else 
      return  postal_search
    end 
  end

  def self.tuncate_zip_code(postal_search)
    if postal_search.length > 5
      return postal_search[0..4]
    else 
      return  postal_search
    end
  end

end
