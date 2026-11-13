# Development and test image only, the gem itself ships no container.
ARG RUBY_VERSION=4.0
FROM ruby:${RUBY_VERSION}-slim

RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends build-essential git libpq-dev libyaml-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /gem
