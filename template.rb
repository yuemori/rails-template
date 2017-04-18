DATABASE_PORT = (32768..61000).to_a.sample

# .gitignore
run 'gibo Linux macOS Ruby Rails Vim > .gitignore' rescue nil
gsub_file '.gitignore', /^config\/secrets.yml\n/, ''
run 'echo ".envrc" >> .gitignore'

create_file 'config/database.yml', <<DATABASE, force: true
default: &default
  adapter: mysql2
  pool: 5
  encoding: utf8mb4
  collation: utf8mb4_bin
  url: <%= ENV['DATABASE_URL'] %>
  database: #{app_name}_<%= ENV['RAILS_ENV'] %>

development:
  <<: *default

test:
  <<: *default

production:
  <<: *default
DATABASE

# Gemfile
create_file 'Gemfile', <<GEMFILE, force: true
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "\#{repo_name}/\#{repo_name}" unless repo_name.include?("/")
  "https://github.com/\#{repo_name}.git"
end

group :default do
  gem 'rails', '~> 5.0.2'
  gem 'slim-rails'
  gem 'puma', '~> 3.0'
  gem 'sass-rails', '~> 5.0'
  gem 'uglifier', '>= 1.3.0'
  gem 'coffee-rails', '~> 4.2'
  gem 'jquery-rails'
  gem 'turbolinks', '~> 5'
  gem 'jbuilder', '~> 2.5'
  gem 'therubyracer'
end

group :development do
  gem 'better_errors'
  gem 'html2slim'
  gem 'listen', '~> 3.0.5'
  gem 'mysql2'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-commands-rubocop'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :development, :test do
  gem 'annotate'
  gem 'awesome_print', require: 'ap'
  gem 'bullet'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'guard'
  gem 'guard-rubocop'
  gem 'guard-rspec'
  gem 'hirb'
  gem 'hirb-unicode-steakknife'
  gem 'pry-byebug'
  gem 'pry-coolline'
  gem 'pry-inline'
  gem 'pry-state'
  gem 'pry-doc'
  gem 'pry-rails'
end

group :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'rspec-rails'
  gem 'database_rewinder'
  gem 'simplecov'
  gem 'launchy'
end
GEMFILE

# install locales
remove_file 'config/locales/en.yml'
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/en.yml -P config/locales/'
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'

# config/application.rb
application do
  %q{
    config.time_zone = 'Tokyo'
    I18n.enforce_available_locales = true
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja
    config.generators do |g|
      g.orm :active_record
      g.template_engine :slim
      g.test_framework :rspec, :fixture => true
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.view_specs false
      g.controller_specs true
      g.routing_specs false
      g.helper_specs false
      g.request_specs false
      g.assets false
      g.helper false
    end
    # config.autoload_paths += %W(#{config.root}/lib)
    # config.autoload_paths += Dir["#{config.root}/lib/**/"]
  }
end

# config/environments/development,test.rb
%w(development test).each do |env|
insert_into_file "config/environments/#{env}.rb", <<RUBY, after: 'config.assets.debug = true'


  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
  end
RUBY
end

# set up rubocop
create_file '.rubocop.yml', <<YAML
AllCops:
  Exclude:
    - 'vendor/**/*'
    - 'bin/*'
    - 'config/**/*'
    - 'Gemfile'
    - 'Guardfile'
    - 'db/**/*'
    - 'tmp/**/*'
    - 'log/**/*'
  DisplayCopNames: true

Style/Documentation:
  Enabled: false

Style/FrozenStringLiteralComment:
  Enabled: false

Style/AsciiComments:
  Enabled: false

Metrics/LineLength:
  Max: 128

Metrics/BlockLength:
  Exclude:
    - 'Rakefile'
    - '**/*.rake'
    - 'spec/**/*.rb'
YAML

# set up Guard
create_file 'Guardfile', %q{
guard :rspec, cmd: 'bin/rspec' do
  require 'guard/rspec/dsl'
  dsl = Guard::RSpec::Dsl.new(self)

  # Feel free to open issues for suggestions and improvements

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)

  # Rails files
  rails = dsl.rails(view_extensions: %w(erb haml slim))
  dsl.watch_spec_files_for(rails.app_files)
  dsl.watch_spec_files_for(rails.views)

  watch(rails.controllers) do |m|
    [
      rspec.spec.call("routing/#{m[1]}_routing"),
      rspec.spec.call("controllers/#{m[1]}_controller"),
      rspec.spec.call("acceptance/#{m[1]}")
    ]
  end

  # Rails config changes
  watch(rails.app_controller)  { "#{rspec.spec_dir}/controllers" }
end

guard :rubocop, all_on_start: false, cmd: 'bin/rubocop' do
  watch(/.+\.rb$/)
  watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
end
}

# Docker
create_file '.dockerignore', <<DOCKERIGNORE, force: true
vendor/bundle
log
tmp
coverage
.git
.bundle
DOCKERIGNORE

create_file 'Dockerfile', <<DOCKERFILE, force: true
FROM ruby:2.4.0

ENV APP_ROOT /usr/src/app
ENV DOCKERIZE_VERSION v0.3.0
ENV ENTRYKIT_VERSION 0.4.0

RUN apt-get update && apt-get install -y wget ca-certificates openssl \\
        # dockerize
        && wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \\
        && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \\
        && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \\
        # entrykit
        && wget https://github.com/progrium/entrykit/releases/download/v${ENTRYKIT_VERSION}/entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \\
        && tar -xvzf entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \\
        && rm entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \\
        && mv entrykit /bin/entrykit \\
        && chmod +x /bin/entrykit \\
        && entrykit --symlink

WORKDIR $APP_ROOT

EXPOSE 3000

ENTRYPOINT [ \\
  "prehook", "bundle install -j4 --quiet", "--", \\
  "prehook", "dockerize -timeout 60s -wait tcp://database:3306", "--" \\
]
DOCKERFILE

create_file 'docker-compose.yml', <<DOCKER_COMPOSE, force: true
version: '2'
services:
  web:
    image: #{app_name}:latest
    container_name: #{app_name}-web
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      - RAILS_ENV=development
      - DATABASE_URL=mysql2://root@database:3306
    ports:
      - '3000:3000'
    networks:
      - default
    volumes:
      - #{app_name}_volume:/usr/local/bundle
      - .:/usr/src/app
    depends_on:
      - database
    tty: true
    stdin_open: true

  database:
    image: mysql:5.7
    container_name: #{app_name}-db
    environment:
      MYSQL_ALLOW_EMPTY_PASSWORD: 'yes'
    ports:
      - '#{DATABASE_PORT}:3306'
    networks:
      - default

volumes:
  #{app_name}_volume:

networks:
  default:
DOCKER_COMPOSE

run 'docker-compose build'
run 'docker-compose up -d database'
run 'docker-compose run --rm web bundle exec rails db:create db:migrate'
run 'docker-compose run --rm -e RAILS_ENV=test web bundle exec rails db:create db:migrate'

# convert erb file to slim
run 'docker-compose run --rm web bundle exec erb2slim -d app/views'

# rspec
run 'docker-compose run --rm web bundle exec rails g rspec:install'

create_file '.rspec', <<EOF, force: true
--color
--format documentation
EOF


create_file 'spec/spec_helper.rb', <<RUBY, force: true
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = [:should, :expect]
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.syntax = [:should, :expect]
  end

  config.order = :random
  config.raise_errors_for_deprecations!
  config.expose_current_running_example_as :example
end
RUBY

create_file 'spec/rails_helper.rb', <<RUBY, force: true
require "simplecov"

SimpleCov.start "rails"

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../../config/environment", __FILE__)
require "spec_helper"
require "rspec/rails"

Dir[Rails.root.join("spec", "support", "**", "*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_path = Rails.root.join('spec', 'fixtures')
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.infer_base_class_for_anonymous_controllers = false

  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    if config.use_transactional_fixtures?
      raise(<<-MSG)
        Delete line `config.use_transactional_fixtures = true` from rails_helper.rb
        (or set it to false) to prevent uncommitted transactions being used in
        JavaScript-dependent specs.
        During testing, the app-under-test that the browser driver connects to
        uses a different database connection to the database connection used by
        the spec. The app's database connection would not be able to access
        uncommitted transaction data setup over the spec's database connection.
      MSG
    end
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before :each do
    DatabaseCleaner.strategy = :transaction
  end

  config.before :each, type: :feature do
    driver_shares_db_connection_with_specs = Capybara.current_driver == :rack_test
    if !driver_shares_db_connection_with_specs
      DatabaseCleaner.strategy = :truncation
    end
  end

  config.before :each do
    DatabaseCleaner.start
  end

  config.after :each do
    DatabaseCleaner.clean
  end
end
RUBY

# set up spring
run 'docker-compose run --rm web bundle exec spring binstub --all'

# README.md

create_file 'README.md', <<README
# #{app_name.camelize}

## setup

```bash
cp .envrc.sample .envrc
```

### use docker

```bash
docker-compose build
docker-compose run --rm web bundle exec rails db:setup
docker-compose run --rm -e RAILS_ENV=test web bundle exec rails db:setup
```

### use local ruby

```bash
bundle install --path vendor/bundle --binstubs vendor/bundle/bin -j4
rails db:setup
RAILS_ENV=test rails db:setup
```
README

# direnv
%w(.envrc .envrc.sample).each do |filename|
create_file filename, <<EOF, force: true
PATH_add vendor/bundle/bin

export DATABASE_URL="mysql2://root@127.0.0.1:#{DATABASE_PORT}"
EOF
end
run 'direnv allow'

# git
git :init
git add: '.'
git commit: '-m "Initial commit"'
