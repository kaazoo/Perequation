class TableExpenses < ActiveRecord::Migration
  def self.up
  	create_table :expenses do |t|
        t.column :datum, :date
        t.column :netto, :float
        t.column :brutto, :float
        t.column :mwst, :float
        t.column :art, :string
        t.column :bezahlt, :boolean
        t.column :abgerechnet, :boolean
        t.column :eintragsdatum, :date
        t.column :geloescht, :boolean, :default => false
        t.column :abrechnung, :string, :null => true
        t.column :user_id, :integer
    end
  end

  def self.down
  	drop_table :expenses
  end
end