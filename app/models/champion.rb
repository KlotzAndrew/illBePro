class Champion < ActiveRecord::Base

def update_champions
p = 1
puts p
while p < 500
  if Champion.where(id: p).empty?
    Champion.create(:id => p)
  end
begin
url = "https://na.api.pvp.net/api/lol/static-data/na/v1.2/champion/#{p}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
remote5_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read
champion_hash = JSON.parse(remote5_data)
Champion.find(p).update(champion: "#{champion_hash["key"]}")
puts champion_hash["key"]
p += 1
rescue OpenURI::HTTPError => ex
puts "KANYE for #{p}"
p += 1
end
end
end

end
