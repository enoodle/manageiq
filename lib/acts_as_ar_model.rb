class ActsAsArModelColumn < ActiveRecord::ConnectionAdapters::Column
  attr_reader :options

  def initialize(name, options)
    type = options.kind_of?(Symbol) ? options : options[:type]
    raise ArgumentError, "type must be specified" if type.nil?

    @options = options.kind_of?(Hash) ? options : {}

    super(name.to_s, @options[:default], VirtualColumn::TYPE_MAP[type.to_sym])
  end
end

class ActsAsArModel
  include Vmdb::Logging

  def self.connection
    ActiveRecord::Base.connection
  end

  def self.sortable?
    false
  end

  def connection
    self.class.connection
  end

  def self.table_name
    nil
  end

  def self.pluralize_table_names
    false
  end

  def self.base_class
    superclass == ActsAsArModel ? self : superclass.base_class
  end

  class << self; alias_method :base_model, :base_class; end

  #
  # Column methods
  #

  def self.columns_hash
    @columns_hash ||= {}
  end

  def self.columns
    @columns ||= columns_hash.values
  end

  def self.column_names
    @column_names ||= columns_hash.keys
  end

  def self.column_names_symbols
    @column_names_symbols ||= column_names.collect(&:to_sym)
  end

  def self.set_columns_hash(hash)
    hash[:id] ||= :integer

    hash.each do |col, options|
      columns_hash[col.to_s] = ActsAsArModelColumn.new(col.to_s, options)

      define_method(col) do
        read_attribute(col)
      end

      define_method("#{col}=") do |val|
        write_attribute(col, val)
      end
    end
  end

  #
  # Reflection methods
  #

  def self.reflections
    @reflections ||= {}
  end

  #
  # Acts As Reportable methods
  #

  class << self
    attr_reader :aar_options
  end

  class << self
    attr_writer :aar_options
  end

  def self.aar_columns
    @aar_columns ||= []
  end

  class << self
    attr_writer :aar_columns
  end

  #
  # Virtual columns and reflections
  #

  extend VirtualFields

  #
  # Attributes
  #

  attr_accessor :attributes

  def self.instances_are_derived?
    true
  end

  def self.reflect_on_association(name)
    virtual_reflection(name)
  end

  def self.compute_type(name)
    ActiveRecord::Base.send :compute_type, name
  end

  def initialize(values = {})
    self.attributes = {}
    values.each do |attr, value|
      send("#{attr}=", value)
    end
  end

  def [](attr)
    attributes[attr.to_s]
  end
  alias_method :read_attribute, :[]

  def []=(attr, value)
    attributes[attr.to_s] = value
  end
  alias_method :write_attribute, :[]=

  #
  # Find routines
  #

  def self.all(*args)
    raise NotImplementedError unless self.respond_to?(:find)
    find(:all, *args)
  end

  def self.first(*args)
    raise NotImplementedError unless self.respond_to?(:find)
    find(:first, *args)
  end

  def self.last(*args)
    raise NotImplementedError unless self.respond_to?(:find)
    find(:last, *args)
  end

  def self.count(*args)
    all(*args).size
  end

  def self.find_by_id(*id)
    options = id.extract_options!
    options.merge!(:conditions => {:id => id.first})
    first(options)
  end

  def self.find_all_by_id(*ids)
    options = ids.extract_options!
    options.merge!(:conditions => {:id => ids.flatten})
    all(options)
  end

  #
  # Methods pulled from ActiveRecord 2.3.8
  #

  # Returns the contents of the record as a nicely formatted string.
  def inspect
    attributes_as_nice_string = self.class.column_names.collect do |name|
      "#{name}: #{attribute_for_inspect(name)}"
    end.compact.join(", ")
    "#<#{self.class} #{attributes_as_nice_string}>"
  end

  private

  # Returns an <tt>#inspect</tt>-like string for the value of the
  # attribute +attr_name+. String attributes are elided after 50
  # characters, and Date and Time attributes are returned in the
  # <tt>:db</tt> format. Other attributes return the value of
  # <tt>#inspect</tt> without modification.
  #
  #   person = Person.create!(:name => "David Heinemeier Hansson " * 3)
  #
  #   person.attribute_for_inspect(:name)
  #   # => '"David Heinemeier Hansson David Heinemeier Hansson D..."'
  #
  #   person.attribute_for_inspect(:created_at)
  #   # => '"2009-01-12 04:48:57"'
  def attribute_for_inspect(attr_name)
    value = self[attr_name]

    if value.kind_of?(String) && value.length > 50
      "#{value[0..50]}...".inspect
    elsif value.kind_of?(Date) || value.kind_of?(Time)
      %("#{value.to_s(:db)}")
    else
      value.inspect
    end
  end
end
