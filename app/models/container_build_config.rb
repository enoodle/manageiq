class ContainerBuildConfig < ActiveRecord::Base
  include CustomAttributeMixin
  include ReportableMixin

  belongs_to :ext_management_system, :foreign_key => "ems_id"
  belongs_to :container_project

  has_many :labels, -> { where(:section => "labels") }, :class_name => "CustomAttribute", :as => :resource, :dependent => :destroy

  acts_as_miq_taggable
end
