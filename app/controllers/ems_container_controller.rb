class EmsContainerController < ApplicationController
  include EmsCommon        # common methods for EmsInfra/Cloud/Container controllers
  include Mixins::EmsCommonAngular
  include Mixins::GenericSessionMixin

  before_action :check_privileges
  before_action :get_session_data
  after_action :cleanup_action
  after_action :set_session_data

  def self.model
    ManageIQ::Providers::ContainerManager
  end

  def self.table_name
    @table_name ||= "ems_container"
  end

  def show_list
    process_show_list(:gtl_dbname => 'emscontainer')
  end

  def ems_path(*args)
    ems_container_path(*args)
  end

  def new_ems_path
    new_ems_container_path
  end

  def ems_container_form_fields
    ems_form_fields
  end

  def launch_common_logging
    route_name = model.find_by_id(params[:id]).common_logging_route_name
    logging_route = ContainerRoute.find_by_name(route_name)
    if logging_route
      url = URI::HTTPS.build(:host => logging_route.host_name)
      render :update do |page|
        page << javascript_prologue
        page << "miqSparkle(false);"
        page << "window.open('#{url}');"
      end
    else
      add_flash(_("A route named '#{route_name}' is configured to connect to the " \
                  "common_logging server but it doesn't exist"), :error)
      javascript_flash
    end
  end

  private

  ############################
  # Special EmsCloud link builder for restful routes
  def show_link(ems, options = {})
    ems_path(ems.id, options)
  end

  def restful?
    true
  end
  public :restful?
end
