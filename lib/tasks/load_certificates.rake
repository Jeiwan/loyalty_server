require 'spreadsheet'

namespace :loyalty do
  desc 'Creates all certificates'
  task load_certificates: :environment do |t, args|
    book = Spreadsheet.open(Rails.root.join('tmp/fmb_certificates.xls'))

    puts '1. Destroying certificates'
    Loyalty::Certificate.find_each do |certificate|
      certificate.destroy
    end
    puts 'Done'

    puts '2. Loading certificates from file'
    certificates = book.worksheets[0].map.with_index do |row, index|
      next if index == 0
      [row[1].to_i, row[-1].to_i.to_s]
    end.compact
    puts 'Done'

    puts '3. Creating certificates'
    columns = ['pin_code', 'number']
    result = Loyalty::Certificate.import(columns, certificates).failed_instances
    puts 'Done'

    next unless result.present?

    result.each do |failed|
      puts "Failed #{failed.number}: #{failed.errors.full_messages.join(' ')}"
    end
  end
end
