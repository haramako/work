# frozen_string_literal: true

require 'redis'

redis = Redis.new(host: "127.0.0.1", db: 0)
redis.flushdb
