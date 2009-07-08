module ActiveRecord
  module Delegation
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      # super_delegates :from => :dest, :except => "id"
      # super_delegates :from => :dest, :only => [ "title", "name" ], :prefix => "src_"
      def super_delegates(*args)
        options = args.pop
        
        raise ArgumentError, "Too many parameters" unless args.empty?
        
        unless options.is_a?(Hash) && from = options[:from]
          raise ArgumentError, "Must specify a source object"
        end
        
        reflection = reflect_on_association(from)
        source_columns = reflection.klass.column_names
        case
          when only = options[:only]: columns = source_columns & Array(only)
          when except = options[:except]: columns = source_columns - Array(except)
          else columns = source_columns
        end

        prefix = options[:prefix]
        columns.each do |column|
          as = prefix.nil? ? column : prefix+column
          super_delegate column, :from => from, :as => as
        end
      end
      
      # super_delegate :col_name, :from => :dest, :as => :new_name
      # super_delegate :col_name, :from => :dest
      def super_delegate(*args)
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
        module_eval(<<-EOS, "super_delegate", 1)
          def #{as}(*args, &block)
            #{from}.nil? ? nil : #{from}.__send__(#{col_name.inspect}, *args, &block)
          end
        EOS
      end
    end
  end
end