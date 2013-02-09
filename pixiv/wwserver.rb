#!/usr/bin/env ruby
# -*- coding:utf-8 -*-

require 'pathname'
HOME = Pathname.new( File.dirname(__FILE__) ) unless defined?(HOME)
$LOAD_PATH << HOME + 'lib'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'erb'
require 'webwalker'
# require 'rack/csrf' TODO: CSRF対策をいれること

get '/' do
  erb :index
end

get '/project' do
  @projects = Project.find(:all)
  @title = 'プロジェクト一覧'
  erb :project_list
end

get '/project/:id' do
  @proj = Project.find( params[:id].to_i )
  @title = @proj.name
  erb :project_view
end

post '/project/create' do
  url = params[:url]
  halt if url == ''
  WebWalker::Handler.add_url WebWalker::Project.new(url,url), url
  redirect '/project'
end

get '/project/delete/:id' do
  id = params[:id].to_i
  @proj = Project.find(id)
  @proj.destroy
  redirect '/project'
end


get '/url' do
  @urls = Url.limit(100).find(:all)
  erb :url_list
end
