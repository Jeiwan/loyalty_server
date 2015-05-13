module Loyalty
  class CardUploadService
    def initialize(file)
      @errors = []
      @file = file
    end

    def process_file
      columns = [:number]
      cards = []

      File.open(@file.tempfile, 'r').each_line do |line|
        processed_line = line.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').gsub(/\s+/, '')
        cards.push([processed_line])
      end

      import_result = Card.import columns, cards
      import_result.failed_instances.each do |failed_card|
        add_error(failed_card.number, failed_card.errors.full_messages.join(', '))
      end

      format_errors if @errors
    end

    private
    
    def add_error(card, message)
      @errors.push({ card: card, message: message })
    end

    def format_errors
      @errors.map do |error|
        "Ошибка в номере #{error[:card]}: #{error[:message]}"
      end
    end
  end
end
