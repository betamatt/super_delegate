module ActiveRecord
  module Delegation
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      # has_columns :from => :dest, :except => "id"
      # has_columns :from => :dest, :only => [ "title", "name" ], :prefix => "src_"
      def has_columns(*args)
        options = args.pop
        
        raise ArgumentError, "Too many parameters" unless args.empty?
        
        unless options.is_a?(Hash) && from = options[:from]
          raise ArgumentError, "Must specify a source object"
        end
        
        source_columns = eval(from.to_s.singularize.capitalize + ".column_names")
        case
          when only = options[:only]: columns = source_columns & Array(only)
          when except = options[:except]: columns = source_columns - Array(except)
          else columns = source_columns
        end

        prefix = options[:prefix]
        columns.each do |column|
          as = prefix.nil? ? column : prefix+column
          has_column column, :from => from, :as => as
        end
      end
      
      # has_column :col_name, :from => :dest, :as => :new_name
      # has_column :col_name, :from => :dest
      def has_column(*args)
        # Parameter wrangling
        options = args.pop; col_name = args.pop
        col_name = col_name.to_sym if col_name.is_a?(String)
        
        raise ArgumentError, "Too many parameters" unless args.empty?
        
        unless options.is_a?(Hash) && col_name.is_a?(Symbol) && from=options[:from] 
          raise ArgumentError, "Must specify a column name and a source object" 
        end

        # Any method renaming going on?
        options[:as].nil? ? as = col_name : as = options[:as]

        # Squirt in the new method
        module_eval(<<-EOS, "has_column", 1)
          def #{as}(*args, &block)
            #{from}.nil? ? nil : #{from}.__send__(#{col_name.inspect}, *args, &block)
          end
        EOS
      end
    end
  end
end