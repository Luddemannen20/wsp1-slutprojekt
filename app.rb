require 'debug'
require "awesome_print"
require 'sinatra'
require 'securerandom'

class App < Sinatra::Base

    
  enable :sessions
  use Rack::Session::Cookie, 
    key: 'rack.session',
    path: '/',
    secret: "cf22c9d6061b3e067155e59d775d4406c92b6afc4aaff0a4131e9165eb2d492b597ace501a3df36043ecba99ae29474acac0cbd8c75fb5f46503b3e90d8b8159"
  
  
  setup_development_features(self)

    # Funktion för att prata med databasen
    # Exempel på användning: db.execute('SELECT * FROM fruits')
    def db
      return @db if @db
      @db = SQLite3::Database.new(DB_PATH)
      @db.results_as_hash = true

      return @db
    end

    # Routen /
    get '/' do
        redirect('/recipes')
    end

    get '/recipes' do
      @recipes = db.execute('SELECT * FROM recipes')
      p @recipes
      erb(:"recipes/index")
    end

    get '/recipes/new' do
      erb(:"recipes/new")
    end

    post '/recipes' do
      p params
      recipe_name = params['recipe_name']
      recipe_time = params['recipe_time']
      recipe_description = params['recipe_description']
      recipe_category = params['recipe_category']
      
      db.execute("INSERT INTO recipes (name, time, description, category) Values(?,?,?,?)", [recipe_name, recipe_time, recipe_description, recipe_category.to_i])
      redirect("/recipes")
    end

    post '/recipes/:id/delete' do | id |
      db.execute('DELETE FROM recipes WHERE id=?', id)
      redirect("/recipes")
    end

    get '/recipes/:id/edit' do | id |
      @recipes = db.execute('SELECT * FROM recipes WHERE id=?', id).first
      erb(:"recipes/edit")
    end

    post '/recipes/:id/update' do | id |
      recipe_name = params['recipe_name']
      recipe_time = params['recipe_time']
      recipe_description = params['recipe_description']
      recipe_category = params['recipe_category']
      db.execute("UPDATE recipes SET name=?, time=?, description=?, category=? WHERE id=?", [recipe_name, recipe_time, recipe_description, recipe_category.to_i, id])
      redirect("/recipes")
    end

    #log in
    configure do
      enable :sessions
      set :session_secret, SecureRandom.hex(64)
    end

    before do
      if session[:user_id]
        @current_user = db.execute("SELECT * FROM users WHERE id = ?", session[:user_id]).first
        ap @current_user
      end
    end

    get '/' do
      erb(:index)
    end

    get '/admin' do 
      if session[:user_id]
        erb(:"admin/index")
      else
        ap "/admin : Acess denied."
        status 401
        redirect '/acess_denied'
      end
    end

    get '/login' do
      erb(:login)
    end

    post '/login' do
      request_username = params[:username]
      request_plain_password = params[:password]

      user = db.execute("SELECT * FROM users WHERE username = ?", request_username).first

      unless user
        ap "/login : Invalid username."
        status 401
        redirect '/acess_denied'
      end

      db_id = user["id"].to_i
      db_password_hashed = user["password"].to_s

      bcrypt_db_password = BCrypt::Password.new(db_password_hashed)

      if bcrypt_db_password == request_plain_password
        ap "/login : Logged in -> redirecting to admin"
        session[:user_id] = db_id
        redirect '/admin'
      else
        ap "/login : Invalid password."
        status 401
        redirect '/acess_denied'
      end
    end

    post 'logout' do
      ap "Logging out"
      session.clear 
      redirect '/'
    end

    get '/users/new' do
      erb(:"users/new")
    end
end
