FROM alpine

WORKDIR /srv/app

RUN apk add --no-cache ruby \
    ruby-dev \
    ruby-io-console \
    ruby-bigdecimal \
    ruby-rdoc \
    ruby-irb \
    tzdata \
    sqlite \
    sqlite-dev \
    git \
    build-base \
    libxml2-dev \
    ruby-bundler

COPY Gemfile .
COPY Gemfile.lock .
COPY draftsman.gemspec .
COPY lib lib/

RUN bundle install

COPY ./ ./

RUN RAILS_ENV=test bundle exec rake -f spec/dummy/Rakefile db:schema:load

CMD rake
