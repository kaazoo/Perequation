class ChangeExpenses < ActiveRecord::Migration
  def self.up
    remove_column "expenses", "abrechnung"
    change_column "expenses", :abgerechnet, :boolean, :default => false
    add_column "expenses", :statement_id, :integer
  end

  def self.down
    add_column "expenses", "abrechnung", :string, :null => true
    change_column "expenses", :abgerechnet, :boolean
    remove_column "expenses", :statement_id
  end
end
