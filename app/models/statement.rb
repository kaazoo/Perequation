class Statement < ActiveRecord::Base

  has_many :gains
  has_many :expenses

end
