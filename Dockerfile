# Matches the newest Ruby in CI (.github/workflows/ci.yml).
FROM ruby:3.3

# chromium runs the Rails system test (test_rails/system) through cuprite.
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    vim \
  && rm -rf /var/lib/apt/lists/*

ENV APP_HOME=/srv/app

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
    BUNDLE_JOBS=8 \
    BUNDLE_PATH=/bundle_cache

WORKDIR $APP_HOME
