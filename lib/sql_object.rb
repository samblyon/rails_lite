require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns = @columns ||
      DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{self.table_name}
        LIMIT
         1
      SQL
      .first.map(&:to_sym)
  end

# It should iterate through all the ::columns, using define_method (twice) to create a getter and setter method for each column, just like my_attr_accessor. But this time, instead of dynamically creating an instance variable, store everything in the #attributes hash.
  def self.finalize!
    columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |row_hash| self.new(row_hash) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL

    parse_all(results).first
  end

  def initialize(params = {})
    self.class.finalize!
    params.each do |column, value|
      unless self.class.columns.include?(column.to_sym)
        raise "unknown attribute \'#{column}\'"
      end

      self.send("#{column}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
      self.send(column)
    end
  end

  def insert
    col_string = self.class.columns.dup
    col_string.delete(:id)
    col_string = col_string.map(&:to_s).join(", ")

    vals = attribute_values[1..-1]
    DBConnection.execute(<<-SQL, *vals)
      INSERT INTO
        #{self.class.table_name} (#{col_string})
      VALUES
        (#{(['?'] * vals.length).join(", ") })
    SQL

    attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    col_string = self.class.columns.dup
    col_string.delete(:id)
    col_string = col_string.map { |col| "#{col} = ?" }.join(", ")

    vals = attribute_values[1..-1]
    id = attribute_values.first
    result = DBConnection.execute(<<-SQL, *vals, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_string}
      WHERE
        id = ?
    SQL
  end

  def save
    if attributes[:id]
      update
    else
      insert
    end
  end
end
