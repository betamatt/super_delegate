require 'activerecord/delegation'

ActiveRecord::Base.class_eval do
  include ActiveRecord::Delegation
end
