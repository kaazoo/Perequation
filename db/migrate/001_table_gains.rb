class TableGains < ActiveRecord::Migration
  def self.up
  	create_table :gains do |t|        t.column :name, :string
        t.column :datum, :date
        t.column :netto, :float
        t.column :brutto, :float
        t.column :mwst, :float
        t.column :bezahlt, :boolean
        t.column :abgerechnet, :boolean
        t.column :eintragsdatum, :date
        t.column :geloescht, :boolean, :default => false
        t.column :abrechnung, :string, :null => true
        t.column :user_id, :integer
    end    
  end

  def self.down
  	drop_table :gains
  end
end
