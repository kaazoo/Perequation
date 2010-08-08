

class Gain < ActiveRecord::Base

  belongs_to :user
  belongs_to :statement

  validates_presence_of :name
  validates_presence_of :netto

  cattr_reader :per_page
  @@per_page = 30

end
