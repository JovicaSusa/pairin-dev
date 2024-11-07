require 'rspec/expectations'

RSpec::Matchers.define :in_array do |expected|
  match do |actual|
    actual.in?(expected)
  end
end
