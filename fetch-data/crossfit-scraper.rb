require 'mechanize'
require 'nokogiri'
require 'json'

mechanize = Mechanize.new
front_page = mechanize.get("http://games.crossfit.com/scores/leaderboard.php?stage=0&sort=0&division=201&region=0&numberperpage=60&page=0&competition=2&frontpage=0&expanded=0&full=1&year=13&showtoggles=0&hidedropdowns=1&showathleteac=1&athletename=")

competition_categories = []
categories = front_page.search "//*[@id=\"lbhead\"]/th/div/span[1]"
categories.each do |category|
  competition_categories << category.text
end

## puts "competition_categories - #{competition_categories}"
## probably not necessary to put up times

final_results = []
competitors = front_page.search "//*[@id=\"lbtable\"]/tbody/tr"
competitors.each_with_index do |competitor, index|
  results = competitor.search "td"

  individual = {}
  results.each_with_index do |result, index|
    # puts result.text

    if index == 0
     placing, scoring = result.text.split(" ")
     score = scoring.split("(")[1].split(")")
     individual["place"] = placing[0].to_i
     individual["score"] = score[0].to_i
    end
    individual["name"] = result.text if index == 1

    if index > 1 && index < 13
      individual["results"] ||={}
      individual["results"][competition_categories[index - 2]] ||= {}

      clean = result.text.delete!("\n")
      current_place = /\d+th|\d+rd|\d+T|WD|CUT/.match(clean)

      points = /\d+ pts/.match(clean)
      if points.nil?
        real_points = 0
      else
        real_points = points[0].split(" pts")[0].to_i
      end
      individual["results"][competition_categories[index - 2]]["points"] = real_points

      if current_place.nil?
        individual["results"][competition_categories[index - 2]]["place"] = -1
      elsif current_place[0] == "WD" || current_place[0] == "CUT"
        individual["results"][competition_categories[index - 2]]["place"] = -1
      else
        individual_place = current_place[0].split("T").first.split("th").first.split("rd").first
        individual["results"][competition_categories[index - 2]]["place"] = individual_place.to_i
      end
    end
    # puts "*" * 80
  end
  final_results << individual if !individual.empty?
end

File.open("crossfit-2013-individual-women.json", "w+") do |f|
  f.write final_results.to_json
end


