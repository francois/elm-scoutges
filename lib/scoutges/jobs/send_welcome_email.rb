# frozen_string_literal: true
require "que"

module Scoutges::Jobs
  class SendWelcomeEmail < Que::Job
    def execute(*args)
      logger.info "args: #{args.inspect}"
      destroy
    end

    def logger
      @logger ||= Logger.new("log/send_welcome_email.log")
    end
  end
end
