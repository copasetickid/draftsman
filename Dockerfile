FROM ruby:2.4-alpine

RUN apk add --no-cache sqlite \
    sqlite-dev \
    git \
    build-base \
    libxml2-dev \
    && gem install bundle

WORKDIR /srv/app

COPY ./ ./

RUN bundle install

# Not picked by bundle in Docker
RUN bundle add bigdecimal \
    && bundle add tzinfo-data

RUN RAILS_ENV=test bundle exec rake -f spec/dummy/Rakefile db:schema:load

CMD rake
