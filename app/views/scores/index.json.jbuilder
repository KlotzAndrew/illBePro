json.array!(@scores) do |score|
  json.extract! score, :id, :summoner_name, :week_1
  json.url score_url(score, format: :json)
end
