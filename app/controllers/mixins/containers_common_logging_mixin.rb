module ContainersCommonLoggingMixin
  def launch_common_logging
    record = self.class.model.find_by_id(params[:id])
    ems = record.ext_management_system
    route_name = ems.common_logging_route_name
    logging_route = ContainerRoute.find_by(:name => route_name, :ems_id => ems.id)
    if logging_route
      query = ({'access_token' => ems.authentication_token,
                'redirect'     => record.common_logging_path}.
                collect{|k,v| k + '=' + v }).join('&')
      url = URI::HTTPS.build(:host  => logging_route.host_name,
                             :path  => '/auth/token',
                             :query => query)
      http = Net::HTTP.new(url.hostname, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      res = http.request(Net::HTTP::Get.new(url.request_uri))
      cookie = res.response['set-cookie'].split(';').first
      url = URI::HTTPS.build(:host  => logging_route.host_name)
      javascript_open_window_with_cookie(url.to_s, cookie)
    else
      render_flash_and_stop_sparkle(_("A route named '#{route_name}' is configured to connect to the " \
                                      "common_logging server but it doesn't exist"), :error)
    end
  end
end
