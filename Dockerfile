FROM ruby:3.1.2

RUN apt-get update -yq && apt-get install -y \
  build-essential \
  && apt-get clean \
  && apt-get autoclean \
  && apt-get install curl gnupg -yq \
  && gem install bundler \
  && echo -n "ruby: " && ruby -v \
  && echo -n "bundler: " && bundler -v


RUN mkdir -p /app
WORKDIR /app

COPY Gemfile .
COPY Gemfile.lock .

RUN bundle config --global frozen 1

RUN bundle config --local deployment true \
    && bundle config --local without "development test" \
    && bundle config --local path vendor \
    && bundle config --local jobs $(nproc) \
    && bundle install

COPY . .

EXPOSE 9292
CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "9292"]
