class AddEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :email, :string, length: 256
  end
end
