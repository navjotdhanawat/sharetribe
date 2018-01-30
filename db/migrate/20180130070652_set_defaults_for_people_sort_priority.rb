class SetDefaultsForPeopleSortPriority < ActiveRecord::Migration[5.1]
  def up
    Person.all.each{|p| p.save }
  end
end
