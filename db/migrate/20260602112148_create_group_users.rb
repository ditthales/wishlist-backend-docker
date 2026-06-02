class CreateGroupUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :group_users do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :group, null: false, foreign_key: { on_delete: :cascade }
      t.index [:user_id, :group_id], unique: true # Evita duplicidade

      t.timestamps
    end
  end
end
