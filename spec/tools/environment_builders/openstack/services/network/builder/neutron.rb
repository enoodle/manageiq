require_relative '../data/neutron'
require_relative 'base'

module Openstack
  module Services
    module Network
      class Builder
        class Neutron < ::Openstack::Services::Network::Builder::Base
          def initialize(ems, project)
            @service = ems.connect(:tenant_name => project.name, :service => "Network")
            @data    = Data::Neutron.new
            @project = project

            # Collected data
            @networks             = []
            @subnets              = []
            @routers              = []
            @floating_ips         = []
            @security_groups      = []
            @security_group_rules = []
          end

          def free_floating_ips
            floating_ips.select { |x| x.port_id.blank? }
          end

          def floating_ip_address(floating_ip)
            floating_ip.floating_ip_address
          end

          private

          def find_or_create_networks
            @data.networks.each do |network|
              network = find_or_create(@service.networks, network.merge(:tenant_id => @project.id))
              find_or_create_subnets(network)

              @networks << network
            end
          end

          def find_or_create_subnets(network)
            return if @data.subnets(network.name).blank?

            @data.subnets(network.name).each do |subnet|
              @subnets << find_or_create(@service.subnets, subnet.merge(:network_id => network.id,
                                                                        :tenant_id  => @project.id))
            end
          end

          def find_or_create_routers
            # First all networks and subnets needs to be created, then we can create routers
            @networks.each do |network|
              next if @data.routers(network.name).blank?
              @data.routers(network.name).each do |router_data|
                router_data       = router_data.merge(:external_gateway_info => network, :tenant_id => @project.id)
                subnet_interfaces = router_data.delete(:__subnets)

                @routers << (find(@service.routers, router_data.slice(:name)) ||
                             create_router(@service.routers, router_data, subnet_interfaces))
              end
            end
          end

          def create_router(collection, data, subnet_interfaces)
            router = create(collection, data)

            # Add private subnets as interface to network
            @subnets.each do |subnet|
              @service.add_router_interface(router.id,
                                            subnet.id) if subnet_interfaces.detect { |x| x[:name] == subnet.name }
            end
          end

          def find_or_create_floating_ips
            @networks.each do |network|
              next if (floating_ips_count = @data.floating_ips(network.name)).blank?

              collection = @service.floating_ips
              @floating_ips += found = collection.select do |i|
                i.tenant_id == @project.id && i.floating_network_id == network.id
              end

              puts "Finding #{found.count} floating ips in #{collection.class.name} for network #{network.name}"

              missing = floating_ips_count - found.count
              next unless missing > 0

              puts "Creating #{missing} floating ips in #{collection.class.name} for network #{network.name}"
              (1..missing).each do
                @floating_ips << collection.create(:floating_network_id => network.id, :tenant_id => @project.id)
              end
            end
          end

          def find_or_create_firewall_rules(security_group)
            return if @data.security_group_rules(security_group.name).blank?

            @data.security_group_rules(security_group.name).each do |security_group_rule|
              security_group_rule = {
                :port_range_min   => nil,
                :port_range_max   => nil,
                :remote_ip_prefix => nil,
                :remote_group_id  => nil
              }.merge(security_group_rule)

              if security_group_rule.delete(:__remote_group_id)
                security_group_rule.merge!(:remote_group_id => security_group.id)
              end

              @security_group_rules << find_or_create(
                @service.security_group_rules,
                security_group_rule.merge!(:tenant_id => @project.id, :security_group_id => security_group.id))
            end
          end
        end
      end
    end
  end
end
