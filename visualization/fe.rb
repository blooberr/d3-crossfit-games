# simple front-end
require 'thin'
require 'sinatra'

get '/' do
  erb :index
end

