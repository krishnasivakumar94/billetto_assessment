class AddEventDetailsAndVotes < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :billetto_id, :string
    add_column :events, :title, :string
    add_column :events, :starts_at, :datetime
    add_column :events, :image_url, :string
    add_column :events, :description, :text
    add_index :events, :billetto_id, unique: true

    create_table :votes do |t|
      t.references :event, null: false, foreign_key: true
      t.string :user_id, null: false
      t.integer :value, null: false
      t.timestamps
    end
    add_index :votes, [:event_id, :user_id], unique: true
    add_check_constraint :votes, "value IN (-1, 1)", name: "votes_value_must_be_valid"
  end
end
