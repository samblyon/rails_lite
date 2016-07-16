require_relative 'associatable'

module Associatable
  def assoc_options
    @assoc_options ||= {}
  end

  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name.to_sym] = options

    define_method(name) do
      foreign_key_num = self.send(options.foreign_key)
      return nil if foreign_key_num.nil?

      model_class = options.class_name.constantize
      result = model_class.where(id: foreign_key_num)

      result.first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)

    define_method(name) do
      primary_key_num = self.send(options.primary_key)
      return nil if primary_key_num.nil?

      model_class = options.class_name.singularize.constantize

      model_class.where("#{options.foreign_key}".to_sym => primary_key_num)
    end
  end

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      start_object_id = attributes[:id]

      through_options = self.class.assoc_options[through_name]
      through_class = through_options.model_class

      source_options = through_class.assoc_options[source_name]
      source_class = source_options.class_name.constantize

      start_table = self.class.table_name
      join_table = through_class.table_name
      source_table = source_options.class_name.constantize.table_name

      start_foreign_key_to_through = through_options.foreign_key
      join_foreign_key_to_source = source_options.foreign_key

      results = DBConnection.execute(<<-SQL, start_object_id)
        SELECT
          #{source_table}.*
        FROM
          #{start_table}
        JOIN
          #{join_table}
        ON
          #{start_table}.#{start_foreign_key_to_through} = #{join_table}.id
        JOIN
          #{source_table}
        ON
          #{source_table}.id = #{join_table}.#{join_foreign_key_to_source}
        WHERE
          #{start_table}.#{start_foreign_key_to_through} = ?
      SQL

      source_class
        .parse_all(results)
        .first
    end
  end
end

class SQLObject
  extend Associatable
end
