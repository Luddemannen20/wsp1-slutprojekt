require 'sqlite3'

class Recipe

  def self.db
      return @db if @db
      @db = SQLite3::Database.new(DB_PATH)
      @db.results_as_hash = true
      return @db
    end
  
  def self.delete(id)
     db.execute('DELETE FROM recipes WHERE id=?', id)
  end

  def self.all()
    return db.execute('SELECT * FROM recipes')
  end

  def self.all_edit(id)
    return db.execute('SELECT * FROM recipes WHERE id=?', id).first
  end
  

  def self.create(recipe_name, recipe_time, recipe_description, recipe_category, user_id)
    db.execute("INSERT INTO recipes (name, time, description, category, user_id) Values(?,?,?,?,?)", [recipe_name, recipe_time, recipe_description, recipe_category.to_i, user_id.to_i])
  end

  def self.edit(recipe_name, recipe_time, recipe_description, recipe_category, id)
    db.execute("UPDATE recipes SET name=?, time=?, description=?, category=? WHERE id=?", [recipe_name, recipe_time, recipe_description, recipe_category.to_i, id])
  end
end