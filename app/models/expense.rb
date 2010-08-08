

class Expense < ActiveRecord::Base

  belongs_to :user
  belongs_to :statement
  
  validates_presence_of :name
  validates_presence_of :netto
  	
end
