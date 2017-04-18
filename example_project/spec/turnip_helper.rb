
require 'capybara/dsl'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'turnip'
require 'turnip/capybara'

Capybara.javascript_driver = :poltergeist
Capybara.ignore_hidden_elements = true
Capybara.run_server = false
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: true, inspector: true, timout: 90)
end

Capybara.configure do |config|
  config.run_server = true
  config.always_include_port = true
  config.default_driver = :rack_test
  config.javascript_driver = :poltergeist
  config.ignore_hidden_elements = false
end

Dir.glob('spec/acceptance/steps/**/*_steps.rb') { |f| load f, true }
