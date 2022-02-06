require 'fileutils'
require 'sqlite3'
require 'sequel'

require './entity'

class SqliteRepository
  def initialize
    @db = Sequel.sqlite('db.sqlite3')
  end

  # users

  def users
    u = []
    @db[:users].each do |row|
      u << User.new(row)
    end
    u
  end

  def get_user(uid)
    row = @db[:users].where(id: uid).first
    if row
      User.new(row)
    else
      User.new(uid)
    end
  end

  def user_last_access(uid)
    row = @db[:commits].where(user_id: uid).order(:num).select(:mtime).last
    if row then row[:mtime] else nil end
  end

  def save_user(user)
    @db[:users].insert_conflict(:replace).insert(user.to_h)
  end

  def delete_user(uid)
    raise
  end

  # commit ids

  def list_commit_ids(uid, limit)
    commits = @db[:commits].select(:user_id, :num, :commit_type, :mtime).where(user_id: uid).reverse(:num).limit(limit).all
    commits.map do |x|
      CommitId.new(x[:user_id], x[:commit_type], x[:num])
    end
  end

  # commits

  def list_commits(uid, limit)
    ids = list_commit_ids(uid, limit)
    ids.map{|id| get_commit(id) }
  end

  def get_commit(commit_id)
    row = @db[:commits].where(user_id: commit_id.user_id, num: commit_id.num, commit_type: commit_id.type).select(:mtime).first
    Commit.new(commit_id, row[:mtime])
  end

  def latest_commit_num(uid)
    row = @db[:commits].where(user_id: uid).order(:num).select(:num).last
    if row then row[:num] else 9999999 end
  end
  
  def get_commit_list(uid, commit_num)
    start_num = last_dump(uid, commit_num)
    commits = @db[:commits].where(user_id: uid, num: (start_num..commit_num)).order(:num).select(:user_id, :num, :commit_type, :mtime)
    commits.map{|row| Commit.new(row) }
  end

  def commit_body(commit_id)
    path = commit_body_path(commit_id)
    IO.binread(path)
  end

  def set_commit_body(commit_id, body)
    path = commit_body_path(commit_id)
    FileUtils.mkdir_p(File.dirname(path))
    IO.binwrite(path, body)
  end

  def commit_body_path(commit_id)
    "commits/#{commit_id.user_id}/#{commit_id.num}_#{commit_id.type}"
  end

  def last_dump(uid, commit_num)
    row = @db[:commits].where(user_id: uid, commit_type: 1).where{ num <= commit_num }.order(:num).reverse.select(:num).first
    if row then row[:num] else 0 end
  end

  def add_commit(uid, commit_num, body)
    @db[:commits].insert_conflict(:replace).insert(user_id: uid, num: commit_num, commit_type: 0, mtime: Time.now.iso8601)
    set_commit_body(CommitId.new(uid, 0, commit_num), body)
  end

  def add_dump(uid, commit_num, body)
    @db[:commits].insert_conflict(:replace).insert(user_id: uid, num: commit_num, commit_type: 1, mtime: Time.now.iso8601)
    set_commit_body(CommitId.new(uid, 1, commit_num), body)
  end


  # export code

  def export_code(user_id, commit_num, key64)
    new_export_code = @db[:export_codes].insert(user_id: user_id, commit_num: commit_num, key64: key64)
  end

  def get_export_code(user_id, commit_num, key64)
    @db[:export_codes].where(user_id: user_id, commit_num: commit_num, key64: key64).first
  end

  def get_export_code_by_id(id)
    @db[:export_codes].where(id: id).first
  end
  
end

