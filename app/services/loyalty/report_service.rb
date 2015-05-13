require 'spreadsheet'

module Loyalty
  class ReportService
    HEADER_ROW = 2

    def initialize(file_name)
      initialize_vars(file_name)
    end

    def save
      adjust_column_widths
      @workbook.write @file_name
    end

    def to_s
      adjust_column_widths
      stream = StringIO.new
      @workbook.write stream
      stream.string
    end

    protected
    
    def initialize_vars(file_name)
      @file_name = file_name
      @workbook = Spreadsheet::Workbook.new
      @sheet = @workbook.create_worksheet
    end

    def set_title(title)
      @sheet.row(0).concat [title]
      @sheet.row(0).default_format = Spreadsheet::Format.new weight: :bold, size: 14
      @title_set = true
    end

    def set_header(columns)
      first_row = @title_set.present? ? HEADER_ROW : 0
      @sheet.row(first_row).concat columns
      @sheet.row(first_row).height = 22
      @sheet.row(first_row).default_format = Spreadsheet::Format.new(
        weight: :bold,
        size: 12,
        horizontal_align: :center,
        vertical_align: :middle
      )
    end

    def add_row(cells, format = nil)
      @sheet.insert_row(@sheet.last_row_index + 1, cells)
      unless format.present?
        format = Spreadsheet::Format.new(
          text_wrap: true, horizontal_align: :left, vertical_align: :top, size: 12
        )
      end

      @sheet.last_row.default_format = format
    end

    def create_sheet(opts = {})
      @sheet = @workbook.create_worksheet opts
    end

    def sheet(number)
      @sheet = @workbook.worksheets[number]
    end

    private

    def adjust_column_widths
      @workbook.worksheets.each do |sheet|
        if @title_set.present?
          sheet.merge_cells(0, 0, 0, sheet.row(HEADER_ROW).size - 1)
        end

        columns = sheet.map.with_index do |row, index|
          next if @title_set.present? && index < HEADER_ROW
          row.map do |cell|
            cell.to_s.split("\n").map(&:size).max
          end
        end.compact

        columns.transpose.each.with_index do |column, index|
          sheet.column(index).width = column.compact.max + 5
        end
      end
    end
  end
end
