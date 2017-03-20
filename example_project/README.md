# ExampleProject

## setup

```bash
docker-compose build
docker-compose run --rm web bundle exec rails db:setup
docker-compose run --rm -e RAILS_ENV=test web bundle exec rails db:setup

bundle install
```
