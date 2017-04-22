# rails-template

## requirements

- docker (v1.10.0+)
- docker-compose
- direnv
- gibo
- ruby
  - bundler

## execute

```bash
curl https://raw.githubusercontent.com/yuemori/rails-template/master/setup.sh | bash -x
bundle install
```

### version specification

```bash
export DATABASE_PORT=3306           # default: random(32768..61000)
export RAILS_VERSION="~> 5.1.0.rc2" # default: 5.0.2
export RUBY_VERSION="2.4.0"         # default: 2.4.1
curl https://raw.githubusercontent.com/yuemori/rails-template/master/setup.sh | bash -x
bundle install
```
