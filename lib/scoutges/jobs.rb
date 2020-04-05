# frozen_string_literal: true
require "que"

module Scoutges::Jobs
end

Dir[File.join(__dir__, "/**/*.rb")].each do |filename|
  require_relative filename.sub("#{__dir__}/", "")
end
