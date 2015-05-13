module Loyalty
  class Logger
    attr_reader :logger

    def initialize
      @logger = ::Logger.new(Rails.root.join('log/loyalty_server.log'))
    end
  end
end
