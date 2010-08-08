class ChangeGains < ActiveRecord::Migration
  def self.up
    remove_column "gains", "abrechnung"
    change_column "gains", :abgerechnet, :boolean, :default => false
    add_column "gains", :statement_id, :integer
  end

  def self.down
    add_column "gains", "abrechnung", :string, :null => true
    change_column "gains", :abgerechnet, :boolean
    remove_column "gains", :statement_id
  end
end
