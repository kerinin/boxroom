module Texticle
  class FullTextIndex # :nodoc:
    attr_accessor :index_columns

    def initialize name, dictionary, model_class, &block
      @name           = name
      @dictionary     = dictionary
      @model_class    = model_class
      @index_columns  = {}
      @string         = nil
      instance_eval(&block)
    end

    def create
      @model_class.connection.execute create_sql
    end

    def destroy
      @model_class.connection.execute destroy_sql
    end

    def create_sql
      <<-eosql
        CREATE index #{@name}
        ON #{@model_class.table_name}
        USING gin((#{to_s}))
      eosql
    end

    def destroy_sql
      "DROP index IF EXISTS #{@name}"
    end

    def to_s
      return @string if @string
      vectors = []
      @index_columns.sort_by { |k,v| k }.each do |weight, columns|
        c = columns.map { |x| "coalesce(#{@model_class.table_name}.#{x}, '')" }
        if weight == 'none'
          vectors << "to_tsvector('#{@dictionary}', #{c.join(" || ' ' || ")})"
        else
          vectors <<
        "setweight(to_tsvector('#{@dictionary}', #{c.join(" || ' ' || ")}), '#{weight}')"
        end
      end
      @string = vectors.join(" || ' ' || ")
    end

    def method_missing name, *args
      weight = args.shift || 'none'
      (index_columns[weight] ||= []) << name.to_s
    end
  end
end
