# -*- coding: utf-8 -*-
class SinatraApp < Sinatra::Base
  get '/' do
    STDERR.puts 'HOGE'
    'Todyea Cabinet Server'
end

get '/u' do
  @users = db.users.sort_by{|u| db.user_last_access(u.id) || Time.parse('2000-01-01')}.reverse
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

  @data = db.dump(CommitId.new(@id, 0, @commit))

  erb :u_dump
end

get '/u/:id/dump/:commit/key/:key64' do
  @id = params['id'].to_i
  @commit = params['commit'].to_i
  @key64 = params['key64']
  @key = Base64.decode64(@key64)
  @user = db.get_user(@id)

  @data = db.dump(CommitId.new(@id, 0, @commit))

  @bin = @data[@key]

  @export_code = db.get_export_code(@id, @commit, @key64)

  erb :u_dump_key
end

get '/u/:id/get/:commit/:key64' do
  @id = params['id'].to_i
  @commit = params['commit'].to_i
  @key64 = params['key64']
  @key = Base64.decode64(@key64)
  bin = db.dump_with_key(CommitId.new(@id, 0, @commit), @key)

  content_type "application/octet-stream"
  attachment "#{@id}-#{@commit}-#{@key64}.bin"
  bin
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

  bin = db.export_code_data(@id)

  content_type "application/octet-stream"
  attachment "export#{@id}.bin"
  bin
end


get '/admin' do
  erb :admin
end

post '/admin/clean' do
  expire_at = Time.now - 24 * 60 * 60 * 2
  db.clean_expired(expire_at)
  redirect '/admin'
end

get '/admin/hoge' do
  a = request.env['omniauth.auth']
  "*#{a.to_s}*"
end

get "/auth/:provider/callback" do
  @provider = params[:provider]
  @result = request.env["omniauth.auth"]
  erb <<-"EOS"
    <a href='/'>Top</a><br/>
    <h1><%= @provider %></h1>
    <pre><%= JSON.pretty_generate(@result) %></pre>
  EOS
end
end
