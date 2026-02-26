require 'debug'
require "awesome_print"

class App < Sinatra::Base

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
end
