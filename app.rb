require 'debug'
require "awesome_print"
require 'sinatra'
require 'securerandom'
require 'bcrypt'
require 'sqlite3'
require_relative 'config'
require_relative 'models/recipe'
require_relative 'models/user'
require_relative 'models/group'

# Huvudklass för applikationen
#
# Klassen hanterar routes, inloggning, användare,
# recept och grupper.
class App < Sinatra::Base
  MAX_LOGIN_ATTEMPTS = 3
  LOCK_TIME = 60
  
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

  # Skickar användaren till receptsidan
  #
  # @return [void]
  # @example
  #   GET /
  #   # redirectar till /recipes
  get '/' do
    redirect('/recipes')
  end

  # Hämtar och visar alla recept
  #
  # @return [void]
  # @example
  #   GET /recipes
  #   # visar sidan med alla recept
  get '/recipes' do
    @recipes = Recipe.all()
    p @recipes
    erb(:"recipes/index")
  end

  # Visar formuläret för att skapa ett nytt recept
  #
  # @return [void]
  # @example
  #   GET /recipes/new
  #   # visar formuläret om användaren är inloggad
  get '/recipes/new' do
    redirect '/access_denied' unless session[:user_id]
    erb(:"recipes/new")
  end

  # Skapar ett nytt recept
  #
  # @return [void]
  # @example
  #   POST /recipes
  #   # sparar ett nytt recept i databasen
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

  # Tar bort ett recept utifrån id
  #
  # @param id [String] id på receptet
  # @return [void]
  # @example
  #   POST /recipes/3/delete
  #   # tar bort receptet med id 3
  post '/recipes/:id/delete' do | id |
    redirect '/access_denied' unless session[:user_id]
  
    @delete = Recipe.delete(id)
    redirect("/recipes")
  end

  # Visar formuläret för att redigera ett recept
  #
  # @param id [String] id på receptet
  # @return [void]
  # @example
  #   GET /recipes/3/edit
  #   # visar edit-sidan för recept 3
  get '/recipes/:id/edit' do | id |
    redirect '/access_denied' unless session[:user_id]
    
    @recipes = Recipe.all_edit(id)
    erb(:"recipes/edit")
  end

  # Uppdaterar ett recept
  #
  # @param id [String] id på receptet
  # @return [void]
  # @example
  #   POST /recipes/3/update
  #   # uppdaterar receptet med id 3
  post '/recipes/:id/update' do | id |
    redirect '/access_denied' unless session[:user_id]
    
    recipe_name = params['recipe_name']
    recipe_time = params['recipe_time']
    recipe_description = params['recipe_description']
    recipe_category = params['recipe_category']
    
    @edit = Recipe.edit(recipe_name, recipe_time, recipe_description, recipe_category, id)
    redirect("/recipes")
  end

  # Visar inloggningssidan
  #
  # @return [void]
  # @example
  #   GET /login
  #   # visar login-sidan
  get '/login' do
    erb(:login)
  end

  # Loggar in en användare.
  #
  # Kontrollerar username och password, hanterar spärr vid för många
  # inloggningsförsök och sparar user_id i sessionen vid lyckad inloggning.
  #
  # @return [void]
  # @example
  # POST /login
  post '/login' do
    request_username = params[:username].to_s.strip
    request_plain_password = params[:password].to_s

    session[:login_attempts] ||= 0
    session[:login_locked_until] ||= nil

    if session[:login_locked_until] && Time.now >= session[:login_locked_until]
      session[:login_attempts] = 0
      session[:login_locked_until] = nil
    end

    if session[:login_locked_until] && Time.now < session[:login_locked_until]
      remaining = (session[:login_locked_until] - Time.now).ceil
      ap "[LOGIN BLOCKED] username=#{request_username} ip=#{request.ip} wait=#{remaining}s"
      halt 429, "För många försök. Du måste vänta #{remaining} sekunder."
    end
    
    user = User.all_username(request_username)


    if user
      db_id = user['id'].to_i
      db_password_hashed = user['password'].to_s
      bcrypt_db_password = BCrypt::Password.new(db_password_hashed)

      if bcrypt_db_password == request_plain_password
        session[:user_id] = db_id
        session[:login_attempts] = 0
        session[:login_locked_until] = nil

        ap "[LOGIN SUCCESS] username=#{request_username} ip=#{request.ip}"
        redirect '/admin'
      end
    end

    session[:login_attempts] += 1
    ap "[LOGIN FAIL] username=#{request_username} ip=#{request.ip} attempts=#{session[:login_attempts]}"

    if session[:login_attempts] >= MAX_LOGIN_ATTEMPTS
      session[:login_locked_until] = Time.now + LOCK_TIME
      ap "[COOLDOWN START] username=#{request_username} ip=#{request.ip} locked_for=#{LOCK_TIME}s"
      halt 429, "För många försök, du måste vänta #{LOCK_TIME} sekunder."
    end

    redirect '/access_denied'
  end

  # Loggar ut den inloggade användaren
  #
  # @return [void]
  # @example
  #   POST /logout
  #   # rensar sessionen och skickar användaren till startsidan
  post '/logout' do
    ap 'Logging out'
    session.clear
    redirect '/'
  end

  # Visar adminsidan om användaren är inloggad
  #
  # @return [void]
  # @example
  #   GET /admin
  #   # visar admin/index
  get '/admin' do 
    if session[:user_id]
      erb(:"admin/index")
    else
      ap "/admin : Access denied."
      redirect '/access_denied'
    end
  end

  # Visar sidan för nekad åtkomst
  #
  # @return [void]
  # @example
  #   GET /access_denied
  #   # visar access_denied-sidan
  get '/access_denied' do
    erb(:access_denied)
  end

  # Visar formuläret för att skapa en ny användare
  #
  # @return [void]
  # @example
  #   GET /users/new
  #   # visar registreringssidan
  get '/users/new' do
    erb(:"users/new")
  end

  # Skapar en ny användare
  #
  # @return [void]
  # @example
  #   POST /users
  #   # sparar en ny användare i databasen
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

  # Tar bort den inloggade användaren
  #
  # @param id [String] id på användaren från URL
  # @return [void]
  # @example
  #   POST /users/5/delete
  #   # tar bort användaren som är inloggad
  post '/users/:id/delete' do
    @delete_user = User.delete(session[:user_id])
    @delete_userRecipes = User.delete_user_recipes(session[:user_id])
    session.clear
    redirect("/login")
  end

  # Visar formuläret för att redigera en användare
  #
  # @param id [String] id på användaren från URL
  # @return [void]
  # @example
  #   GET /users/5/edit
  #   # visar edit-sidan för den inloggade användaren
  get '/users/:id/edit' do | id |
    id = session[:user_id]
    
    @user = User.all(id)
    halt 404, "User not found" unless @user

    erb(:"users/edit")
  end

  # Uppdaterar lösenordet för den inloggade användaren
  #
  # @return [void]
  # @example
  #   POST /users/5/update
  #   # uppdaterar användarens lösenord
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

  # Visar grupper som användaren har gått med i
  # och grupper som användaren inte gått med i
  #
  # @return [void]
  # @example
  #   GET /groups
  #   # visar gruppsidan
  get '/groups' do
    
    @groups = Group.joined_for_user(session[:user_id])
    @other_groups = Group.not_joined_for_user(session[:user_id])

    erb(:"groups/index")
  end

  # Låter användaren gå med i en grupp
  #
  # @param id [String] id på gruppen
  # @return [void]
  # @example
  #   POST /groups/2/join
  #   # användaren går med i grupp 2
  post '/groups/:id/join' do | id |

    Group.join(session[:user_id], id)
    redirect '/groups'
  end
end