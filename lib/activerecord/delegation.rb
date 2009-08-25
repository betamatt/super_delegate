module ActiveRecord
  module Delegation
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      # super_delegates :from => :dest, :except => "id"
      # super_delegates :from => :dest, :only => [ "title", "name" ], :prefix => "src_"
      def super_delegates(options)                
        unless options.is_a?(Hash) && from = options[:from]
          raise ArgumentError, "Must specify a source association"
        end
        
        reflection = reflect_on_association(from)
        case
          when only = options[:only]: columns = Array(only)
            
          # These options are dangerous!  Forcing the model to hit the db during initialization breaks rake when the 
          # table doesn't exist yet.
          when except = options[:except]: columns = reflection.klass.column_names - Array(except)
          else columns = reflection.klass.column_names
        end

        prefix = options[:prefix]
        columns.each do |column|
          as = prefix.nil? ? column : prefix+column
          super_delegate column, :from => from, :as => as
        end
      end
      
      # super_delegate :col_name, :from => :dest, :as => :new_name
      # super_delegate :col_name, :from => :dest
      def super_delegate(col_name, options)      
        unless options.is_a?(Hash) && from=options[:from] 
          raise ArgumentError, "Must specify a source association" 
        end

        # Any method renaming going on?
        as = options[:as].nil? ? col_name : options[:as]

        # Squirt in the new method
        module_eval(<<-EOS, "super_delegate", 1)
          def #{as}(*args, &block)
            #{from}.send(:#{col_name}, *args, &block)
          end
          
          def #{as}=(*args, &block)
            #{from}.send(:#{col_name}=, *args, &block)
          end
          
          after_validation lambda {|obj| 
            if obj.#{from} && errors = obj.#{from}.errors.on(:#{col_name})
              errors.each {|e| obj.errors.add(:#{as}, e)}
            end  
          }
        EOS
      end
    end
  end
end