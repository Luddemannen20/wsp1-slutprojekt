require 'sqlite3'

class User 
  
  def self.db
      return @db if @db
      @db = SQLite3::Database.new(DB_PATH)
      @db.results_as_hash = true
      return @db
    end

  def self.all(id)
    return @current_user = db.execute("SELECT * FROM users WHERE id = ?", id).first
  end

  def self.all_username(request_username)
    return db.execute("SELECT * FROM users WHERE username = ?", [request_username]).first
  end

  def self.create(username, hashed_password)
    db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, hashed_password])
  end

  def self.delete(user_id)
    db.execute('DELETE FROM users WHERE id=?', user_id)
  end

  def self.delete_user_recipes(user_id)
    db.execute('DELETE FROM recipes WHERE user_id=?', user_id)
  end
end