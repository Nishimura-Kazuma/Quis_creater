class AddIncludeInExportToBooks < ActiveRecord::Migration[6.1]
  def change
    add_column :books, :include_in_export, :boolean, default: true
  end
end
