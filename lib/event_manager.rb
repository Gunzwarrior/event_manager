require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def hour_from_registration_date(date)
  date_array = date.split
  hour = Time.parse(date_array[1]).hour
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^0-9]/, '')
  
  if phone_number.length < 10 ||
     phone_number.length > 11 ||
     (phone_number.length == 11 && !phone_number.match?('1', 0))
    phone_number = 'Wrong number'
  elsif phone_number.length == 11 && phone_number.match?('1', 0)
    phone_number = phone_number.sub('1', '')
  end
  phone_number
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

best_hour = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])
  registration_hour = hour_from_registration_date(row[:regdate])
  best_hour.push(registration_hour)
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end
overview = Hash.new(0)
best_hour.each do |hour|
  overview[hour] += 1
end
p overview