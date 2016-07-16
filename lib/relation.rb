require_relative 'searchable'

class Relation < SQLObject
  extend Searchable
  attr_reader :class, :sql

  def initialize(sql)
    @sql = sql
    target_obj_table_name = @sql[/(?<=SELECT).*(?=\.\*|\*)/]
    if target_obj_table_name.strip.empty?
      target_obj_table_name = @sql[/(?<=FROM).*(?=WHERE)/].strip
    end

    @class = target_obj_table_name.singularize.camelcase.constantize
  end

  def where_lazy(params)
    if params.is_a?(String)
      where_string = params
    else
      where_string = params.map do |attr_name, value|
        if value.is_a?(String)
          value = "\'#{value}\'"
        end

        "#{attr_name} = #{value}"
      end

      where_string = where_string.join(" AND ")
    end

    sql = @sql + "AND #{where_string}"

    sql = sql.gsub("\n", "").gsub(/\s+/," ")
    output = Relation.new(sql)
  end

  def method_missing(name, *args)
    results = self.load
    results.send(name, *args)
  rescue
    debugger
  end

  def load
    results = DBConnection.execute(@sql)
    results.map {|hash| @class.new(hash) }
  end

  def each &prc
    self.load.each &prc
  end
end
