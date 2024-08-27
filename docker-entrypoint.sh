#!/bin/sh

set -e

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

bundle exec ./bin/rails assets:precompile
RAILS_LOG_TO_STDOUT=true bundle exec ./bin/rails s -b 0.0.0.0
# bundle exec puma -p 28080 config/cable/config.ru
