class DropPostComments < ActiveRecord::Migration[6.1]
  def change
    drop_table :post_comments
  end
end
