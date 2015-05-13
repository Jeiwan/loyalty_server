require 'spreadsheet'

module SpreadsheetParser
  class << self
    def parse_report(file_name, type, sheet_number = 0)
      book = Spreadsheet.open file_name
      sheet1 = book.worksheets[sheet_number]
      sheet1.map.with_index do |row, index|
        next if index < 3
        parse_row(row, type, sheet_number)
      end.compact
    end

    private

    def parse_row(row, type, sheet_number = 0)
      if type == :cards
        {
          card: row[0],
          balance: row[1],
          receipt: row[2],
          pharmacy: row[3],
          pharmacy_code: row[4],
          user: row[5]
        }
      elsif type == :purchases
        {
          card: row[0],
          receipt: row[1],
          positions: row[2],
          pharmacy: row[3],
          pharmacy_code: row[4],
          cashbox: row[5],
          user: row[6]
        }
      elsif type == :gifts && sheet_number == 0
        {
          card: row[0],
          receipt: row[1],
          gift: row[2],
          pharmacy: row[3],
          pharmacy_code: row[4],
          user: row[5]
        }
      elsif type == :gifts && sheet_number == 1
        {
          gift_name: row[0],
          category: row[1],
          quantity: row[2]
        }
      end
    end
  end
end
