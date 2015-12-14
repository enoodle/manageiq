class CreateContainerBuildConfigs < ActiveRecord::Migration
  def change
    create_table :container_build_configs do |t|
      t.string     :ems_ref
      t.string     :name
      t.timestamp  :creation_timestamp
      t.string     :resource_version
      t.belongs_to :container_project, :type => :bigint
      t.belongs_to :ems, :type => :bigint
    end
    add_index :container_build_configs, :ems_id
  end
end
