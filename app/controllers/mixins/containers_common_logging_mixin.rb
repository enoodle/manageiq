module ContainersCommonLoggingMixin
  def launch_common_logging
    record = self.class.model.find_by_id(params[:id])
    route_name = record.ext_management_system.common_logging_route_name
    logging_route = ContainerRoute.find_by_name(route_name)
    if logging_route
      url = URI::HTTPS.build(:host  => logging_route.host_name,
                             :query => record.common_logging_query)
      javascript_open_window(url.to_s)
    else
      render_flash_and_stop_sparkle(_("A route named '#{route_name}' is configured to connect to the " \
                                      "common_logging server but it doesn't exist"), :error)
    end
  end
end
