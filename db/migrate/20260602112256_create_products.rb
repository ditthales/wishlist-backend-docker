class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.references :group, null: false, foreign_key: { on_delete: :cascade }
      
      # Configuração correta das chaves estrangeiras apontando para users
      t.references :added_by, null: false, foreign_key: { to_table: :users }
      t.references :bought_by, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      
      t.string :name, null: false
      t.text :description
      t.text :store_link
      t.text :image_link
      
      # MUDOU AQUI: Adicione a precisão e escala no preço
      t.decimal :price, precision: 10, scale: 2
      
      t.string :for_whom
      t.boolean :bought, default: false, null: false

      t.timestamps
    end
  end
end