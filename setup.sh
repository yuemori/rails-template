#!/bin/bash

set -eux

rm -rf Gemfile

bundle init

echo "gem 'rails'" >> Gemfile

bundle install --path vendor/bundle --binstubs vendor/bundle/bin -j 4

vendor/bundle/bin/rails new . --skip-bundle --skip-test --force --template=https://raw.githubusercontent.com/yuemori/rails-template/master/template.rb

bundle install --path vendor/bundle --binstubs vendor/bundle/bin --jobs=4
