# frozen_string_literal: true
require "que"

module Scoutges::Jobs
  class Bingo < Que::Job
    def execute(*args)
      logger.warning "Bingo: #{args.inspect}"
      destroy
    end

    def logger
      LOGGER
    end
  end
end
