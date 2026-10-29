class AddBillettoUrlToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :billetto_url, :string
  end
end
