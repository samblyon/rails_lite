require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)
    where_string = params.map do |attr_name, value|
      if value.is_a?(String)
        value = "\'#{value}\'"
      end

      "#{attr_name} = #{value}"
    end.join(" AND ")

    result = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_string}
    SQL

    result.map { |row_hash| self.new(row_hash) }
  end

  def where_lazy(params)
    where_string = params.map do |attr_name, value|
      if value.is_a?(String)
        value = "\'#{value}\'"
      end

      "#{attr_name} = #{value}"
    end.join(" AND ")

    sql = """
          SELECT
            *
          FROM
            #{self.table_name}
          WHERE
            #{where_string}
          """

    sql = sql.gsub("\n", "").gsub(/\s+/," ")

    output = Relation.new(sql)
  end
end

class SQLObject
  extend Searchable
end
