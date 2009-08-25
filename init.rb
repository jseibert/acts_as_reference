# Include hook code here
ActiveRecord::Base.send(:include, ActsAsReference::ActiveRecord::Base)