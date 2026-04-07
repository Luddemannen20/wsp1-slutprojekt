require 'debug'
require "awesome_print"
require 'sinatra'
require 'securerandom'
require 'bcrypt'
require 'sqlite3'
require_relative 'config'
require_relative 'models/recipe'
require_relative 'models/user'

class App < Sinatra::Base
  
  setup_development_features(self)

  configure do
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
  end

    before do
      if session[:user_id]
        @current_user = User.all(session[:user_id])
        ap @current_user
      end
    end

    get '/' do
        redirect('/recipes')
    end

    get '/recipes' do
      @recipes = Recipe.all()
      p @recipes
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
      
      @create = Recipe.create(recipe_name, recipe_time, recipe_description, recipe_category, user_id)
      redirect("/recipes")
    end

    post '/recipes/:id/delete' do | id |
      redirect '/access_denied' unless session[:user_id]
    
      @delete = Recipe.delete(id)
      redirect("/recipes")
    end

    get '/recipes/:id/edit' do | id |
      redirect '/access_denied' unless session[:user_id]
      
      @recipes = Recipe.all_edit(id)
      erb(:"recipes/edit")
    end

    post '/recipes/:id/update' do | id |
      redirect '/access_denied' unless session[:user_id]
      
      recipe_name = params['recipe_name']
      recipe_time = params['recipe_time']
      recipe_description = params['recipe_description']
      recipe_category = params['recipe_category']
      
      @edit = Recipe.edit(recipe_name, recipe_time, recipe_description, recipe_category, id)
      redirect("/recipes")
    end

    #log in:
    get '/login' do
      erb(:login)
    end

    post '/login' do
      request_username = params[:username]
      request_plain_password = params[:password]

      user = User.all_username(request_username)

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

      existing_user = User.all_username(username)

      if existing_user
        @error = "Användarnamnet finns redan!"
        return erb(:"users/new")
      end

      hashed_password = BCrypt::Password.create(password)

      @create_user = User.create(username, hashed_password)
      redirect '/login'
    end

    post '/users/:id/delete' do
      @delete_user = User.delete(session[:user_id])
      @delete_userRecipes = User.delete_user_recipes(session[:user_id])
      session.clear
      redirect("/login")
    end

    get '/users/:id/edit' do | id |
      id = session[:user_id]
      
      @user = User.all(id)
      halt 404, "User not found" unless @user

      erb(:"users/edit")
    end

    post '/users/:id/update' do
      
      id = session[:user_id]
      password = params[:password]

      if password.empty?
        return "Password cannot be empty"
      else 
        hashed_password = BCrypt::Password.create(password)
        @update_password = User.edit(hashed_password, id)
        redirect('/admin')
      end
    end
end