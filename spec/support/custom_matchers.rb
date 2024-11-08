require 'rspec/expectations'

RSpec::Matchers.define :in_array do |expected|
  match do |actual|
    actual.in?(expected)
  end
end

RSpec::Matchers.define :have_one_of_the_texts do |expected|
  match do |actual|
    expected.any? { |text| CGI.unescapeHTML(actual.body).match(%r{#{text}}) }
  end
end
