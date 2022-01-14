#!/usr/bin/ruby
# frozen_string_literal: true

module ToydeaCabinet
  class Cabinet
    attr_reader :data
    attr_reader :path

    def initialize(path_or_io = nil)
      if path_or_io.respond_to?(:read)
        @data = Reader.new.read(path_or_io)
      elsif path_or_io
        @path = path_or_io
        open(@path, 'rb') do |f|
          @data = Reader.new.read(f)
        end
      else
        @data = {}
        @commit_id = 0
      end
    end

    def put(key, val)
      @data[key] = val
    end

    def get(key)
      @data[key]
    end

    def [](key)
      @data[key]
    end

    def []=(key, val)
      @data[key] = val
    end
  end

  class Reader
    attr_reader :data, :first_commit, :last_commit

    attr_accessor :f # 一時的に外に出す

    def initialize; end

    def read(io)
      @data = {}
      @f = io

      read_header
      read_commit until @f.eof?
      raise "Invalid commit size" unless @f.eof?

      @first_commit ||= 0
      @last_commit ||= 0
      # puts "read key=#{@data.size}, commit #{@first_commit}~#{@last_commit}"
      @data
    end

    def merge_commit(data, commit_bin)
      @first_commit = nil
      @last_commit = nil
      @data = data
      @f = StringIO.new(commit_bin)
      read_header

      read_commit until @f.eof?

      raise "Invalid commit size" unless @f.eof?
      @first_commit ||= 0
      @last_commit ||= 0
      # puts "read key=#{@data.size}, commit #{@first_commit}~#{@last_commit}"
      @data
    end

    def split_chunks(commit_bin)
      chunks = []
      @f = StringIO.new(commit_bin)
      read_header
      until @f.eof?
        size = read_int
        chunks << (int_to_bin(size) + @f.read(size))
      end
      chunks
    end

    # private # 一時的にpublicに

    def read_byte
      @f.read(1)[0].ord
    end

    def read_int
      n = 0
      i = 0
      while i < 4
        c = read_byte
        n |= (c & 0x7f) << (i * 7)
        return n if c < 0x80
        i += 1
      end
      raise "invalid number"
    end

    def int_to_bin(n)
      buf = []
      i = 0
      while i < 4
        if n <= 0x80
          buf << n
          return buf.pack('c*')
        else
          buf << ((n & 0x7f) | 0x80)
          n = n >> 7
        end
        i += 1
      end
      raise "invalid number"
    end

    def read_span
      len = read_int - 1
      if len < 0
        raise "len must not be -1"
      else
        @f.read(len)
      end
    end

    def read_block
      key = read_span
      len = read_byte
      if len == 0
        @data.delete key
      else
        @f.ungetc len.chr
        val = read_span
        @data[key] = val
      end
    end

    def read_commit
      size = read_int
      orig_pos = @f.pos
      crc = @f.read(4) # TODO: 読み捨てしているのをちゃんと利用する
      commit_id = read_int
      @first_commit ||= commit_id
      puts "Invalid commit id, expect #{@last_commit + 1} but #{commit_id}" if @last_commit && @last_commit + 1 != commit_id
      @last_commit = commit_id
      # puts "commit #{commit_id} #{size}"
      read_block while @f.pos < orig_pos + size
      raise "Invalid commit size, expect #{size} but #{@f.pos - orig_pos}" if size != @f.pos - orig_pos
    end

    def read_header
      header = @f.read(3)
      raise "Invalid header" if header != "TC\x01"
    end
  end
end
