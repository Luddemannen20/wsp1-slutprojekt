class Recipe

  def Delete()
    return db.execute('DELETE FROM recipes WHERE id=?', ?)
  end


end