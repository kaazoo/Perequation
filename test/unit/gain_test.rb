require File.dirname(__FILE__) + '/../test_helper'

class GainTest < Test::Unit::TestCase
  fixtures :gains

	NEW_GAIN = {}	# e.g. {:name => 'Test Gain', :description => 'Dummy'}
	REQ_ATTR_NAMES 			 = %w( ) # name of fields that must be present, e.g. %(name description)
	DUPLICATE_ATTR_NAMES = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)

  def setup
    # Retrieve fixtures via their name
    # @first = gains(:first)
  end

  def test_raw_validation
    gain = Gain.new
    if REQ_ATTR_NAMES.blank?
      assert gain.valid?, "Gain should be valid without initialisation parameters"
    else
      # If Gain has validation, then use the following:
      assert !gain.valid?, "Gain should not be valid without initialisation parameters"
      REQ_ATTR_NAMES.each {|attr_name| assert gain.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"}
    end
  end

	def test_new
    gain = Gain.new(NEW_GAIN)
    assert gain.valid?, "Gain should be valid"
   	NEW_GAIN.each do |attr_name|
      assert_equal NEW_GAIN[attr_name], gain.attributes[attr_name], "Gain.@#{attr_name.to_s} incorrect"
    end
 	end

	def test_validates_presence_of
   	REQ_ATTR_NAMES.each do |attr_name|
			tmp_gain = NEW_GAIN.clone
			tmp_gain.delete attr_name.to_sym
			gain = Gain.new(tmp_gain)
			assert !gain.valid?, "Gain should be invalid, as @#{attr_name} is invalid"
    	assert gain.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
 	end

	def test_duplicate
    current_gain = Gain.find_first
   	DUPLICATE_ATTR_NAMES.each do |attr_name|
   		gain = Gain.new(NEW_GAIN.merge(attr_name.to_sym => current_gain[attr_name]))
			assert !gain.valid?, "Gain should be invalid, as @#{attr_name} is a duplicate"
    	assert gain.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
		end
	end
end

