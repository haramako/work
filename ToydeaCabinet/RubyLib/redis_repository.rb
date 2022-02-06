require 'redis'
require './entity'

class RedisRepository
  def initialize
    @redis = Redis.new(host: "127.0.0.1", db: (ENV['REDIS_DB'] || 0).to_i)
  end

  # users

  def users
    @redis.keys('U*').map do |key|
      split_key1(key)
    end
  end

  def get_user(uid)
    data = @redis.get(make_user_key(uid))
    if data
      data = User.new(JSON.parse(data, symbolize_names: true))
    else
      data = User.new(id)
    end
    data
  end

  def save_user(user)
    @redis.set make_user_key(user.id), JSON.dump(user.to_h)
  end

  def delete_user(uid)
    @redis.del make_user_key(uid)
    @redis.del make_idx_key(uid)
    @redis.del make_commit_prefix(uid)
    @redis.del make_dump_prefix(uid)
  end

  # commit keys

  def list_commit_ids(uid, limit)
    keys = @redis.zrevrange(make_idx_key(uid), 0, limit)
    keys.map do |x|
      type, _, c = split_key(x)
      CommitId.new(uid, type, c)
    end
  end

  # commits

  def list_commits(uid, limit)
    ids = list_commit_ids(uid, limit)
    ids.map{|id| get_commit(id) }
  end

  def get_commit(commit_id)
    key = make_commit_key(commit_id)
    mtime = Time.parse(@redis.get(key + ':t'))
    body = @redis.get(make_commit_key(commit_id))
    Commit.new(commit_id, body, mtime)
  end

  def add_commit(uid, commit_num, body)
    commit_id = CommitId.new(uid, 'C', commit_num)
    key = make_commit_key(commit_id)
    @redis.set key, body
    @redis.set key + ':t', Time.now.iso8601
    @redis.zadd make_idx_key(key), commit_num, key
  end

  # dumps

  def add_dump(uid, commit_id, body)
    key = make_dump_key(id, r.first_commit)
    @redis.set key, body
    @redis.set key + ':t', Time.now.iso8601
    @redis.zadd make_idx_key(id), commit_id, key
  end

  private

  # key manipulation utilities

  def pack_key(*args)
    args.map do |x|
      if x.is_a? Integer
        '%08d' % [x]
      else
        x
      end
    end.join
  end

  def split_key1(key)
    e = key.unpack('aa10')
    e[1].to_i
  end

  def split_key(key)
    e = key.unpack('aa10a8')
    [e[0], e[1].to_i, e[2].to_i]
  end

  # key generators

  def make_commit_key(commit_id)
    pack_key(commit_id.type, commit_id.user_id, commit_id.num)
  end

  def make_commit_prefix(id)
    pack_key('C', id, '*')
  end

  def make_dump_key(id, commit)
    pack_key('D', id, commit)
  end

  def make_dump_prefix(id)
    pack_key('D', id, '*')
  end

  def make_user_key(id)
    pack_key('U', id)
  end

  def make_idx_key(id)
    pack_key('Z', id)
  end

end

