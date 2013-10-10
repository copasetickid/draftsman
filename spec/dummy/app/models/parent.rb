class Parent < ActiveRecord::Base
  has_drafts
  has_many :children, :dependent => :destroy
  has_many :bastards, :dependent => :destroy
end
