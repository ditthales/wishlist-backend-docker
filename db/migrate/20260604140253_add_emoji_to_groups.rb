class AddEmojiToGroups < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :emoji, :string
  end
end
