require 'sqlite3'

class Group
  
  def self.db
    return @db if @db
    @db = SQLite3::Database.new(DB_PATH)
    @db.results_as_hash = true
    return @db
  end

  def self.all()
    db.execute('SELECT * FROM groups')
  end

  def self.joined_for_user(user_id)
    db.execute('SELECT * FROM groups
    JOIN group_members ON groups.id = group_members.group_id
    WHERE group_members.user_id = ?', [user_id])
  end

  def self.not_joined_for_user(user_id)
    db.execute('SELECT * FROM groups WHERE id NOT IN (SELECT group_id FROM group_members WHERE user_id = ?)', [user_id])
  end

  def self.join(user_id, group_id)
    db.execute('INSERT INTO group_members (user_id, group_id) VALUES (?, ?)', [user_id, group_id])
  end
end