FROM ruby:3.2.2-alpine AS chat

RUN apk --update add \
    build-base \
    tzdata \
    yarn \
    libc6-compat \
    postgresql-dev \
    postgresql-client \
    mysql-client \
    mysql-dev \
    redis \
    imagemagick \
    imagemagick-dev \
    curl \
    libjpeg-turbo \
    && rm -rf /var/cache/apk/*

WORKDIR /app

COPY Gemfile* /app/
RUN gem update --system 3.5.17
RUN gem install bundler -v $(tail -n 1 Gemfile.lock)
RUN bundle config set without 'development test'
RUN bundle check || bundle install
RUN bundle clean --force

COPY package.json yarn.lock /app/
RUN yarn install --check-files

COPY . /app/

EXPOSE 3000

ENTRYPOINT ["./docker-entrypoint.sh"]