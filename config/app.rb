# frozen_string_literal: true

require "bundler"
Bundler.require :default, ENV.fetch("RAILS_ENV", ENV.fetch("RACK_ENV", "development")).to_sym

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

Dir[File.join(File.expand_path("..", __dir__), "config", "initializers", "**", "*.rb")].sort.each do |initializer|
  load initializer
end

require "scoutges"
