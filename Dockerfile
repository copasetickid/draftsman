ARG  VERSION
FROM ruby:${VERSION}-alpine

RUN apk add --no-cache git build-base
RUN apk add --no-cache sqlite sqlite-dev
RUN apk add --no-cache tzdata

RUN mkdir -p /srv/app
WORKDIR /srv/app

COPY Gemfile .
COPY draftsman.gemspec .
COPY lib/draftsman/version.rb lib/draftsman/version.rb
RUN bundle install

COPY Appraisals .
COPY gemfiles .
RUN bundle exec appraisal install

COPY . /srv/app

RUN RAILS_ENV=test bundle exec rake -f spec/dummy/Rakefile db:schema:load
CMD bundle exec appraisal rake
