require File.dirname(__FILE__) + '/../test_helper'

class ExpenseTest < Test::Unit::TestCase
  fixtures :expenses

	NEW_EXPENSE = {}	# e.g. {:name => 'Test Expense', :description => 'Dummy'}
	REQ_ATTR_NAMES 			 = %w( ) # name of fields that must be present, e.g. %(name description)
	DUPLICATE_ATTR_NAMES = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)

  def setup
    # Retrieve fixtures via their name
    # @first = expenses(:first)
  end

  def test_raw_validation
    expense = Expense.new
    if REQ_ATTR_NAMES.blank?
      assert expense.valid?, "Expense should be valid without initialisation parameters"
    else
      # If Expense has validation, then use the following:
      assert !expense.valid?, "Expense should not be valid without initialisation parameters"
      REQ_ATTR_NAMES.each {|attr_name| assert expense.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"}
    end
  end

	def test_new
    expense = Expense.new(NEW_EXPENSE)
    assert expense.valid?, "Expense should be valid"
   	NEW_EXPENSE.each do |attr_name|
      assert_equal NEW_EXPENSE[attr_name], expense.attributes[attr_name], "Expense.@#{attr_name.to_s} incorrect"
    end
 	end

	def test_validates_presence_of
   	REQ_ATTR_NAMES.each do |attr_name|
			tmp_expense = NEW_EXPENSE.clone
			tmp_expense.delete attr_name.to_sym
			expense = Expense.new(tmp_expense)
			assert !expense.valid?, "Expense should be invalid, as @#{attr_name} is invalid"
    	assert expense.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
 	end

	def test_duplicate
    current_expense = Expense.find_first
   	DUPLICATE_ATTR_NAMES.each do |attr_name|
   		expense = Expense.new(NEW_EXPENSE.merge(attr_name.to_sym => current_expense[attr_name]))
			assert !expense.valid?, "Expense should be invalid, as @#{attr_name} is a duplicate"
    	assert expense.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
		end
	end
end

