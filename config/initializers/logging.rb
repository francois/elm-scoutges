# frozen_string_literal: true

require "logger"
LOGGER ||=
  begin
    Logger.new(STDERR).tap do |logger|
      logger.level = Logger::DEBUG
      logger.formatter = ->(level, timestamp, _, msg) do
        "%-15.15s [%-5.5s] - %s\n" % [timestamp.strftime("%H:%M:%S.%N"), level, msg]
      end
    end
  end
