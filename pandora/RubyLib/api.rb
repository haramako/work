post '/api/u/:id/delete' do
  id = params['id'].to_i
  # session_key = SecureRandom.uuid
  db.delete_user(id)

  'ok'
end

post '/api/u/:id/login' do
  id = params['id'].to_i
  json = JSON.parse(request.body.read, symbolize_names: true)
  name = json[:name]

  u = db.get_user(id)
  u.session_key = SecureRandom.uuid
  u.name = name if name
  db.save_user(u)

  json(sessionKey: u.session_key, lastCommit: u.last_commit || 0)
end

post '/api/u/:id/commit' do
  u = validate_session
  id = params['id'].to_i
  body = request.body.read
  # puts "body commit #{body.size} #{body[0..8].each_byte.to_a}"

  r = ToydeaCabinet::Reader.new
  _ = r.merge_commit({}, body)
  commit_num = r.first_commit || 0

  u.last_commit = commit_num
  db.save_user(u)

  db.add_commit(id, commit_num, body)

  'ok'
end

post '/api/u/:id/dump' do
  u = validate_session
  id = params['id'].to_i
  body = request.body.read
  # puts "body dump #{body.size} #{body[0..8].each_byte.to_a}"

  raise "too large body #{body.size}" if body.size > 60_000_000

  r = ToydeaCabinet::Reader.new
  _ = r.merge_commit({}, body)
  commit_num = r.first_commit

  u.last_commit = commit_num
  db.save_user(u)

  db.add_dump(id, commit_num, body)

  'ok'
end

