class TableStatements < ActiveRecord::Migration
  def self.up
    create_table :statements do |t|        t.column :name, :string
        t.column :einnahmen_netto, :float
        t.column :einnahmen_brutto, :float
        t.column :ausgaben_netto, :float
        t.column :ausgaben_brutto, :float
        t.column :gewinn_netto, :float
        t.column :gewinn_brutto, :float
        t.column :erstellungsdatum, :date
    end
    
  end

  def self.down
    drop_table :statements
  end
end
