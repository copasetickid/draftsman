FROM alpine

WORKDIR /srv/app

RUN apk add --no-cache ruby \
    ruby-dev \

    ruby-bundler \
    ruby-bigdecimal \
    ruby-io-console \
    ruby-irb \
    ruby-rdoc \

    tzdata \

    sqlite \
    sqlite-dev \

    git \

    build-base \
    libxml2-dev

COPY Gemfile .
COPY Gemfile.lock .
COPY draftsman.gemspec .
COPY lib/draftsman/version.rb lib/draftsman/version.rb

RUN bundle install

COPY ./ ./

RUN RAILS_ENV=test bundle exec rake -f spec/dummy/Rakefile db:schema:load

CMD rake
