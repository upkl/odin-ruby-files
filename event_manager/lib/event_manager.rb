require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(number)
  if number.to_s.length == 10
    number
  elsif number.to_s.length == 11
    if number[0] == '1'
      number[1..]
    else
      nil
    end
  else
    nil
  end                             
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

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('/tmp/output') unless Dir.exist?('/tmp/output')

  filename = "/tmp/output/thanks_#{id}.html"

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

hours = {}
wday = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)

  begin
    regdate = DateTime.parse(row[:regdate])
    h = regdate.hour
    hours[h] = hours.fetch(h, 0) + 1
    
    wd = regdate.wday
    wday[wd] = wday.fetch(wd, 0) + 1
  rescue
  end
end

hours_max = hours.max_by{ |hour, count| count}
wday_max = wday.max_by{ |wday, count| count}

puts "Peak hour: #{hours_max[0]}"
puts "Peak wday: #{wday_max[0]}"
