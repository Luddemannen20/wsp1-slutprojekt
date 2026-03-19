require 'debug'
require "awesome_print"
require 'sinatra'
require 'securerandom'
require 'bcrypt'
require 'sqlite3'
require_relative 'config'

class App < Sinatra::Base
  
  setup_development_features(self)

  configure do
    enable :sessions
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
        @current_user = db.execute("SELECT * FROM users WHERE id = ?", [session[:user_id]]).first
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
      redirect '/access_denied' unless session[:user_id]
      erb(:"recipes/new")
    end

    post '/recipes' do
      redirect '/access_denied' unless session[:user_id]

      recipe_name = params['recipe_name']
      recipe_time = params['recipe_time']
      recipe_description = params['recipe_description']
      recipe_category = params['recipe_category']
      user_id = session[:user_id]
      
      db.execute("INSERT INTO recipes (name, time, description, category, user_id) Values(?,?,?,?,?)", [recipe_name, recipe_time, recipe_description, recipe_category.to_i, user_id.to_i])
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
      redirect '/access_denied' unless session[:user_id]
      
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
      request_username = params[:username]
      request_plain_password = params[:password]

      user = db.execute("SELECT * FROM users WHERE username = ?", [request_username]).first

      unless user
        ap "/login : Invalid username."
        status 401
        redirect '/access_denied'
      end

      db_id = user['id'].to_i
      db_password_hashed = user['password'].to_s

      bcrypt_db_password = BCrypt::Password.new(db_password_hashed)

      if bcrypt_db_password == request_plain_password
        ap "/login : Logged in -> redirecting to admin"
        session[:user_id] = db_id
        redirect '/admin'
      else
        ap "/login : Invalid password."
        redirect '/access_denied'
      end
    end

    post '/logout' do
      ap 'Logging out'
      session.clear
      redirect '/'
    end

    get '/admin' do 
      if session[:user_id]
        erb(:"admin/index")
      else
        ap "/admin : Access denied."
        redirect '/access_denied'
      end
    end

    get '/access_denied' do
      erb(:access_denied)
    end

    get '/users/new' do
      erb(:"users/new")
    end

    post '/users' do
      username = params[:username]
      password = params[:password]

      if username.to_s.strip.empty? || password.to_s.strip.empty?
        @error = "Fyll i användarnamn och lösenord!"
        return erb(:"users/new")
      end

      existing_user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first

      if existing_user
        @error = "Användarnamnet finns redan!"
        return erb(:"users/new")
      end

      hashed_password = BCrypt::Password.create(password)

      db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, hashed_password])
      redirect '/login'
    end
  end



    