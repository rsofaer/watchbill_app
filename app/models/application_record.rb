class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def z3_id
    "#{self.class.name}_#{id}".to_sym
  end
end
