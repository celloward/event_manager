require "csv"
require "google/apis/civicinfo_v2"
require "erb"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_num(phone_num)
  stripped_num = phone_num.to_s.scan(/\d/).join
    .match(/^1?(\d{10})$/)
  stripped_num ? stripped_num[1] : "Invalid number. Request number from registrant."
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"
  
  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"]    
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

puts "Event manager initialized. Populating form letters in ./output/"
puts "Phone list for mobile engagement:"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
  #Parse relevant CSV info
  id = row[0]
  
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  phone_num = clean_phone_num(row[:homephone])

  puts "Name: #{name}, Phone: #{phone_num}"

  #Create form letter for each registrant with their US representatives and contact info.
  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)
end