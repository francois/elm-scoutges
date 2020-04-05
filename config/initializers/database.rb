# frozen_string_literal: true

require "sequel"
require_relative "logging"

DB ||= Sequel.connect(ENV.fetch("DATABASE_URL", "postgres://postgrest:supersecretpassword@localhost/scoutges_development"), logger: LOGGER)
