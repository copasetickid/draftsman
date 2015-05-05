class Parent < ActiveRecord::Base
  has_drafts
  has_many :children, :dependent => :destroy
  has_many :bastards, :dependent => :destroy
  has_one :only_child, :dependent => :destroy
end
