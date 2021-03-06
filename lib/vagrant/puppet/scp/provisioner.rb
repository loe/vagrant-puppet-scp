require 'log4r'

module Vagrant
  module Puppet
    module Scp
      class PuppetScpError < Vagrant::Errors::VagrantError
        error_namespace('vagrant.provisioners.puppet_scp')
      end

      class Provisioner < Vagrant.plugin(2, :provisioner)
        def initialize(machine, config)
          super

          @logger = Log4r::Logger.new('vagrant::provisioners::puppet_scp')
        end

        def configure(root_config)
          # Calculate the paths we're going to use based on the environment
          root_path = @machine.env.root_path
          @expanded_manifests_path = @config.expanded_manifests_path(root_path)
          @expanded_modules_path = @config.expanded_modules_path(root_path)
          @manifest_file = File.join(@config.manifests_guest_path, @config.manifest_file)
        end

        def provision
          create_guest_path
          share_manifests
          share_modules
          verify_binary('puppet')
          run_puppet_apply
        end

        def create_guest_path
          @machine.communicate.tap do |comm|
            comm.sudo("mkdir -p #{@config.guest_path}")
            comm.sudo("chown -R #{@machine.ssh_info[:username]} #{@config.guest_path}")
          end
        end

        def share_manifests
          recursive_scp(@expanded_manifests_path, @config.manifests_guest_path)
        end

        def share_modules
          recursive_scp(@expanded_modules_path, @config.modules_guest_path)
        end

        def verify_binary(binary)
          @machine.communicate.sudo(
            "which #{binary}",
            :error_class => PuppetScpError,
            :error_key => :not_detected,
            :binary => binary)
        end

        def run_puppet_apply
          options = [config.options].flatten
          options << "--modulepath '#{@config.modules_guest_path}'" if !@config.modules_guest_path.empty?
          options << @manifest_file
          options = options.join(" ")

          # Build up the custom facts if we have any
          facter = ""
          if !config.facter.empty?
            facts = []
            config.facter.each do |key, value|
              facts << "FACTER_#{key}='#{value}'"
            end

            facter = "#{facts.join(" ")} "
          end

          command = "#{facter}puppet apply #{options} || [ $? -eq 2 ]"
          
          @machine.env.ui.info I18n.t("vagrant.provisioners.puppet.running_puppet",
                                      :manifest => @config.manifest_file)

          @machine.communicate.sudo(command) do |type, data|
            data.chomp!
            @machine.env.ui.info(data, :prefix => false) if !data.empty?
          end
        end

        def recursive_scp(from, to)
          @machine.communicate.tap do |comm|
            comm.sudo("rm -rf #{to}")
            comm.sudo("mkdir -p #{to}")
            comm.sudo("chown #{@machine.ssh_info[:username]} #{to}")
          end

          Dir.glob("#{from}/**/*") do |path|
            to_path = path.gsub(from.to_s, '') # Remove the local cruft

            if File.directory?(path)
              @machine.communicate.execute("mkdir -p #{to}#{to_path}")
            else
              @machine.communicate.upload(path, "#{to}#{to_path}")
            end
          end
        end
      end
    end
  end
end

