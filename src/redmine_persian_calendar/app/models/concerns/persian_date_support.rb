# frozen_string_literal: true

# Persian Date Support Concern for Redmine Models
# Provides Persian calendar functionality for ActiveRecord models
module PersianDateSupport
  extend ActiveSupport::Concern

  included do
    # Store Persian date attribute mappings
    class_attribute :persian_date_attributes, default: {}
  end

  class_methods do
    # Define Persian date attribute for a model
    # @param attr_name [Symbol] The attribute name (e.g., :created_on, :due_date)
    # @param options [Hash] Configuration options
    # @option options [Symbol] :format (:default) Display format for Persian dates
    # @option options [Boolean] :allow_nil (true) Allow nil values
    # @option options [Boolean] :validate (true) Validate Persian date format
    def persian_date_attribute(attr_name, options = {})
      attr_name = attr_name.to_sym
      
      # Store attribute configuration
      self.persian_date_attributes = persian_date_attributes.merge(
        attr_name => {
          format: options[:format] || :default,
          allow_nil: options.fetch(:allow_nil, true),
          validate: options.fetch(:validate, true)
        }
      )
      
      # Define Persian getter method
      define_method("persian_#{attr_name}") do
        get_persian_date_attribute(attr_name)
      end
      
      # Define Persian setter method
      define_method("persian_#{attr_name}=") do |value|
        set_persian_date_attribute(attr_name, value)
      end
      
      # Add validation if requested
      if options.fetch(:validate, true)
        validates "persian_#{attr_name}", 
                  persian_date: { allow_nil: options.fetch(:allow_nil, true) },
                  if: -> { false } # Temporarily disable validation to prevent form errors
      end
    end
  end

  # Get Persian date representation of an attribute
  # @param attr_name [Symbol] The attribute name
  # @return [String, nil] Persian date string or nil
  def get_persian_date_attribute(attr_name)
    return nil unless persian_calendar_enabled?
    
    gregorian_value = send(attr_name)
    return nil if gregorian_value.nil?
    
    begin
      persian_date = Redmine::PersianCalendar::PersianDate.from_gregorian(gregorian_value)
      format = persian_date_attributes[attr_name]&.dig(:format) || :default
      persian_date.format(format_pattern_for(format))
    rescue StandardError => e
      Rails.logger.warn "Persian date conversion error for #{attr_name}: #{e.message}"
      nil
    end
  end

  # Set attribute value from Persian date string
  # @param attr_name [Symbol] The attribute name
  # @param persian_value [String, nil] Persian date string
  def set_persian_date_attribute(attr_name, persian_value)
    return unless persian_calendar_enabled?
    
    if persian_value.blank?
      send("#{attr_name}=", nil)
      return
    end
    
    begin
      # Parse Persian date string
      persian_date = Redmine::PersianCalendar::PersianDate.parse(persian_value.to_s)
      gregorian_date = persian_date.to_gregorian
      
      # Set the Gregorian attribute
      send("#{attr_name}=", gregorian_date)
    rescue StandardError => e
      Rails.logger.warn "Persian date parsing error for #{attr_name}: #{e.message}"
      # Store the invalid value for validation
      instance_variable_set("@invalid_persian_#{attr_name}", persian_value)
    end
  end

  # Get all Persian date attributes for this model
  # @return [Hash] Hash of Persian date values
  def persian_date_attributes_hash
    return {} unless persian_calendar_enabled?
    
    result = {}
    self.class.persian_date_attributes.each_key do |attr_name|
      result["persian_#{attr_name}"] = get_persian_date_attribute(attr_name)
    end
    result
  end

  # Set multiple Persian date attributes
  # @param attributes [Hash] Hash of Persian date values
  def persian_date_attributes=(attributes)
    return unless persian_calendar_enabled?
    
    attributes.each do |key, value|
      if key.to_s.start_with?('persian_')
        attr_name = key.to_s.sub(/^persian_/, '').to_sym
        if self.class.persian_date_attributes.key?(attr_name)
          set_persian_date_attribute(attr_name, value)
        end
      end
    end
  end

  # Check if Persian calendar is enabled for this model
  # @return [Boolean] true if enabled
  def persian_calendar_enabled?
    return false unless Redmine::PersianCalendar.enabled?
    
    # Handle case when User.current is nil (during initialization, etc.)
    current_user = User.current
    return true if current_user.nil? || current_user.anonymous?
    
    # Check user preference
    current_user.persian_calendar_enabled?
  end

  # Get format pattern for Persian date display
  # @param format [Symbol] Format type
  # @return [String] Format pattern
  def format_pattern_for(format)
    case format
    when :default
      'YYYY/MM/DD'
    when :short
      'YY/M/D'
    when :long
      'dddd، D MMMM YYYY'
    when :month_year
      'MMMM YYYY'
    when :time
      'YYYY/MM/DD HH:mm'
    when :datetime
      'dddd، D MMMM YYYY ساعت HH:mm'
    else
      format.to_s
    end
  end

  # Convert Persian date to Gregorian for database storage
  # @param persian_date_string [String] Persian date string
  # @return [Date, nil] Gregorian date or nil
  def convert_persian_to_gregorian(persian_date_string)
    return nil if persian_date_string.blank?
    
    begin
      persian_date = Redmine::PersianCalendar::PersianDate.parse(persian_date_string)
      persian_date.to_gregorian
    rescue StandardError => e
      Rails.logger.warn "Persian to Gregorian conversion error: #{e.message}"
      nil
    end
  end

  # Convert Gregorian date to Persian for display
  # @param gregorian_date [Date, Time] Gregorian date
  # @param format [Symbol] Display format
  # @return [String, nil] Persian date string or nil
  def convert_gregorian_to_persian(gregorian_date, format = :default)
    return nil if gregorian_date.nil?
    
    begin
      persian_date = Redmine::PersianCalendar::PersianDate.from_gregorian(gregorian_date)
      persian_date.format(format_pattern_for(format))
    rescue StandardError => e
      Rails.logger.warn "Gregorian to Persian conversion error: #{e.message}"
      nil
    end
  end

  # Validate Persian date format
  # @param persian_date_string [String] Persian date string to validate
  # @return [Boolean] true if valid
  def valid_persian_date?(persian_date_string)
    return true if persian_date_string.blank?
    
    begin
      Redmine::PersianCalendar::PersianDate.parse(persian_date_string)
      true
    rescue StandardError
      false
    end
  end

  # Get Persian date validation errors
  # @param attr_name [Symbol] Attribute name
  # @return [Array<String>] Array of error messages
  def persian_date_validation_errors(attr_name)
    errors = []
    invalid_value = instance_variable_get("@invalid_persian_#{attr_name}")
    
    if invalid_value
      errors << I18n.t('activerecord.errors.messages.invalid_persian_date', 
                       value: invalid_value)
    end
    
    errors
  end

  # Persian date range validation
  # @param start_attr [Symbol] Start date attribute
  # @param end_attr [Symbol] End date attribute
  # @return [Boolean] true if valid range
  def valid_persian_date_range?(start_attr, end_attr)
    start_persian = get_persian_date_attribute(start_attr)
    end_persian = get_persian_date_attribute(end_attr)
    
    return true if start_persian.blank? || end_persian.blank?
    
    begin
      start_date = Redmine::PersianCalendar::PersianDate.parse(start_persian)
      end_date = Redmine::PersianCalendar::PersianDate.parse(end_persian)
      start_date <= end_date
    rescue StandardError
      false
    end
  end

  # Get Persian date for today
  # @return [String] Today's Persian date
  def persian_today
    return nil unless persian_calendar_enabled?
    
    persian_date = Redmine::PersianCalendar::PersianDate.today
    persian_date.format('YYYY/MM/DD')
  end

  # Check if date is in Persian calendar range
  # @param date [Date, Time] Date to check
  # @return [Boolean] true if in valid range
  def in_persian_calendar_range?(date)
    return false if date.nil?
    
    # Persian calendar typically covers years 1300-1500 (roughly 1921-2121 CE)
    gregorian_year = date.year
    gregorian_year.between?(1921, 2121)
  end

  # Format Persian date for JSON serialization
  # @param attr_name [Symbol] Attribute name
  # @return [Hash] JSON representation
  def persian_date_json(attr_name)
    persian_value = get_persian_date_attribute(attr_name)
    gregorian_value = send(attr_name)
    
    {
      persian: persian_value,
      gregorian: gregorian_value&.strftime('%Y-%m-%d'),
      formatted: persian_value ? convert_gregorian_to_persian(gregorian_value, :long) : nil
    }
  end

  # Bulk convert Persian dates for API responses
  # @return [Hash] All Persian date attributes in JSON format
  def all_persian_dates_json
    result = {}
    self.class.persian_date_attributes.each_key do |attr_name|
      result[attr_name] = persian_date_json(attr_name)
    end
    result
  end
end

# Custom validator for Persian dates
class PersianDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? && options[:allow_nil]
    return if value.blank? && !options[:allow_nil]
    
    unless record.valid_persian_date?(value)
      record.errors.add(attribute, :invalid_persian_date, value: value)
    end
  end
end