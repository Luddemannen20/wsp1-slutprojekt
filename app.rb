require 'debug'
require "awesome_print"
require 'sinatra'
require 'securerandom'
require 'bcrypt'
require 'sqlite3'
require 'bcrypt'
require '../config'

class App < Sinatra::Base
  
  setup_development_features(self)

  configure do
    enable :session
    set :session_secret, SecureRandom.hex(64)
  end

  def db
      return @db if @db
      @db = SQLite3::Database.new(DB_PATH)
      @db.results_as_hash = true
      return @db
    end

    before do
      if session[:user_id]
        @current_user = db.execute("SELECT * FROM users WHERE id = ?", session[:user_id]).first
        ap @current_user
      end
    end

    get '/' do
        redirect('/recipes')
    end

    get '/recipes' do
      @recipes = db.execute('SELECT * FROM recipes')
      erb(:"recipes/index")
    end

    get '/recipes/new' do
      redirect 'access_denied' unless session[:user_id]
      erb(:"recipes/new")
    end

    post '/recipes' do
      redirect '/acess_denied' unless session[:user_id]

      recipe_name = params['recipe_name']
      recipe_time = params['recipe_time']
      recipe_description = params['recipe_description']
      recipe_category = params['recipe_category']
      
      db.execute("INSERT INTO recipes (name, time, description, category) Values(?,?,?,?)", [recipe_name, recipe_time, recipe_description, recipe_category.to_i])
      redirect("/recipes")
    end

    post '/recipes/:id/delete' do | id |
      redirect '/access_denied' unless session[:user_id]
    
      db.execute('DELETE FROM recipes WHERE id=?', id)
      redirect("/recipes")
    end

    get '/recipes/:id/edit' do | id |
      redirect '/access_denied' unless session[:user_id]
      
      @recipes = db.execute('SELECT * FROM recipes WHERE id=?', id).first
      erb(:"recipes/edit")
    end

    post '/recipes/:id/update' do | id |
      redirect '/acess_denied' unless session[:user_id]
      
      recipe_name = params['recipe_name']
      recipe_time = params['recipe_time']
      recipe_description = params['recipe_description']
      recipe_category = params['recipe_category']
      db.execute("UPDATE recipes SET name=?, time=?, description=?, category=? WHERE id=?", [recipe_name, recipe_time, recipe_description, recipe_category.to_i, id])
      redirect("/recipes")
    end

    #log in:
    get '/login' do
      erb(:login)
    end

    post '/login' do
      
    end


    