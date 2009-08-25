# ActsAsReference::ActiveRecord::Base
module ActsAsReference::ActiveRecord::Base
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      class << self
        alias_method_chain :has_one, :reference
        alias_method_chain :belongs_to, :reference
      end
    end
  end

  module ClassMethods
    def acts_as_reference(reference_id, options = {})
      if options[:create]
        finder = "self.find_or_create_by_#{reference_id}(reference)"
      else
        finder = "self.find_by_#{reference_id}(reference)"
      end
      self.class_eval(
        <<-EVAL
          def self.reference_id
            "#{reference_id}"
          end
          def self.find_using_reference(reference)
            unless reference.nil? || reference.blank?
              obj = #{finder}
            else
              obj = nil
            end
            obj
          end
          def self.[](reference)
            find_using_reference(reference)
          end
        EVAL
      )
      self.class_eval(
        <<-EVAL
          def to_s
            self.#{reference_id}
          end
        EVAL
      )
    end
    
    def has_one_with_reference(association_id, options = {})
      self.has_one_without_reference(association_id, options)
      
      if !options[:polymorphic]
        reflection = self.reflect_on_association(association_id)
        if reflection.klass.respond_to?(:find_using_reference)
          alias_method "associate_#{association_id}=", "#{association_id}="
          self.class_eval(
            <<-EVAL
              def #{association_id}_#{reflection.klass.reference_id}
                self.#{association_id}.#{reflection.klass.reference_id} rescue nil
              end
              def #{association_id}_#{reflection.klass.reference_id}=(reference)
                self.#{association_id} = reference
              end
              def #{association_id}=(reference)
                #{association_id} = (reference.is_a?(#{reflection.klass}) ? reference : #{reflection.klass}.find_using_reference(reference))
                self.associate_#{association_id} = #{association_id}
              end
            EVAL
          )
        end
      end
    end

    def belongs_to_with_reference(association_id, options = {})
      self.belongs_to_without_reference(association_id, options)
      
      if !options[:polymorphic]
        reflection = self.reflect_on_association(association_id)
        if reflection.klass.respond_to?(:find_using_reference)
          alias_method "associate_#{association_id}=", "#{association_id}="
          self.class_eval(
            <<-EVAL
              def #{association_id}_#{reflection.klass.reference_id}
                self.#{association_id}.#{reflection.klass.reference_id} rescue nil
              end
              def #{association_id}_#{reflection.klass.reference_id}=(reference)
                self.#{association_id} = reference
              end
              def #{association_id}=(reference)
                #{association_id} = (reference.is_a?(#{reflection.klass}) ? reference : #{reflection.klass}.find_using_reference(reference))
                self.associate_#{association_id} = #{association_id}
              end
            EVAL
          )
        end
      end
    end
  end
end
