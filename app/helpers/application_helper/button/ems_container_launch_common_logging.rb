class ApplicationHelper::Button::EmsContainerLaunchCommonLogging < ApplicationHelper::Button::GenericFeatureButton
  def initialize(view_context, view_binding, instance_data, props)
    props ||= {}
    props.store_path(:options, :feature, :common_logging)
    super(view_context, view_binding, instance_data, props)
  end

  def disabled?
    !visible? || ContainerRoute.find_by(:name => @record.common_logging_route_name,
                                        :ems_id => @record.id).blank?
  end
end
