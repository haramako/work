class User
  attr_reader :id
  attr_accessor :name
  attr_accessor :session_key
  attr_accessor :last_commit

  def initialize(id_or_json)
    if id_or_json.is_a? Numeric
      @id = id_or_json
      @name = '(unknown)'
      @session_key = ''
      @last_commit = 0
    else
      d = id_or_json
      @id = d[:id]
      @name = d[:name]
      @session_key = d[:session_key]
      @last_commit = d[:last_commit]
    end
  end

  def to_h
    {id: @id, session_key: @session_key, last_commit: @last_commit, name: @name}
  end

  def to_s
    @name
  end
end

class CommitId
  attr_reader :user_id, :type, :num

  def initialize(user_id, type, num)
    @user_id = user_id
    @type = type
    @num = num
  end
end

class Commit
  attr_reader :id, :mtime, :export_code

  def initialize(*args)
    if args.size == 1
      raise "arg[0] must be Hash but #{args[0]}" unless args[0].is_a? Hash
      d = args[0]
      @id = CommitId.new(d[:user_id], d[:commit_type], d[:num])
      @mtime = d[:mtime]
      @export_code = d[:export_code]
    elsif args.size == 2
      id, mtime = *args
      @id = id
      @mtime = mtime
      @export_code = nil
    else
      raise "invalid args #{args}"
    end
  end
end

