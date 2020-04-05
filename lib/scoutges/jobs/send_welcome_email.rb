# frozen_string_literal: true
require "logger"
require "que"

module Scoutges::Jobs
  class SendWelcomeEmail < Que::Job
    def run(*args)
      logger.info "#{self.class}.run(#{args.inspect})"
      destroy
    end

    def logger
      @logger ||=
        begin
          Logger.new("log/send_welcome_email.log").tap do |logger|
            logger.level = Logger::DEBUG
            logger.formatter = ->(level, timestamp, _, msg) do
              "%-15.15s [%-5.5s] - %s\n" % [timestamp.strftime("%H:%M:%S.%N"), level, msg]
            end
          end
        end
    end
  end
end
