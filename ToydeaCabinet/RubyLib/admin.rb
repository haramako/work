# -*- coding: utf-8 -*-
get '/' do
  'Todyea Cabinet Server'
end

get '/u' do
  @users = db.users.sort_by{|u| db.user_last_access(u.id)}.reverse
  erb :u
end

get '/u/:id/list' do
  @id = params['id'].to_i
  limit = (params[:limit] || 100).to_i
  @commits = db.list_commits(@id, limit)
  
  erb :u_list
end

get '/u/:id/commit/:kind/:commit' do
  @id = params['id'].to_i
  @user = db.get_user(@id)
  @commit = params['commit'].to_i
  kind = params['kind'].to_i

  @data = {}
  r = ToydeaCabinet::Reader.new
  commit_id = CommitId.new(@id, kind, @commit)
  c = db.get_commit(commit_id)
  r.merge_commit(@data, db.commit_body(commit_id))

  erb :u_dump
end

get '/u/:id/latest' do
  id = params['id'].to_i
  commit = db.latest_commit_num(id)
  redirect "/u/#{id}/dump/#{commit}"
end

get '/u/:id/dump/:commit' do
  @id = params['id'].to_i
  @user = db.get_user(@id)
  @commit = params['commit'].to_i
  list = db.get_commit_list(@id, @commit)

  @data = {}
  r = ToydeaCabinet::Reader.new
  list.each do |commit|
    r.merge_commit(@data, db.commit_body(commit.id))
  end

  erb :u_dump
end

get '/u/:id/dump/:commit/key/:key64' do
  @id = params['id'].to_i
  @commit = params['commit'].to_i
  @key64 = params['key64']
  @key = Base64.decode64(@key64)
  @user = db.get_user(@id)
  list = db.get_commit_list(@id, @commit)

  @data = {}
  r = ToydeaCabinet::Reader.new
  list.each do |commit|
    r.merge_commit(@data, db.commit_body(commit.id))
  end

  @bin = @data[@key]

  @export_code = db.get_export_code(@id, @commit, @key64)

  erb :u_dump_key
end

get '/u/:id/get/:commit/:key64' do
  @id = params['id'].to_i
  @commit = params['commit'].to_i
  @key64 = params['key64']
  @key = Base64.decode64(@key64)
  list = db.get_commit_list(@id, @commit)

  @data = {}
  r = ToydeaCabinet::Reader.new
  list.each do |commit|
    r.merge_commit(@data, db.commit_body(commit.id))
  end

  bin = @data[@key]

  content_type "application/octet-stream"
  attachment "#{@id}-#{@commit}-#{@key64}.bin"
  bin
end

get '/u/:id/bdump/:commit' do
  id = params['id'].to_i
  commit = params['commit'].to_i
  list = db.get_commit_list(id, commit)

  out = []
  first = true
  list.each do |commit|
    body = db.commit_body(commit.id)
    if first
      first = false
      out << body
    else
      out << body[3..-1] # ヘッダーを削る
    end
  end

  content_type "application/octet-stream"
  attachment "u%8d-c%8d.tc" % [id, commit]
  out.join
end

get '/u/:id/export_code/:commit/:key64' do
  @id = params['id'].to_i
  @commit = params['commit'].to_i
  @key64 = params['key64']

  db.export_code(@id, @commit, @key64)

  redirect "/u/#{@id}/dump/#{@commit}/key/#{@key64}"
end

get '/export_code/:id' do
  @id = params['id'].to_i
  @export_code = db.get_export_code_by_id(@id)

  redirect "/u/#{@export_code[:user_id]}/get/#{@export_code[:commit_num]}/#{@export_code[:key64]}"
end
