# ExampleProject

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
