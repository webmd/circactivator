#
# Author:: Adam Leff (<aleff@webmd.net>)
# Copyright:: Copyright (c) 2015 WebMD, LLC
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'thor'

module CircActivator
  class CLI < Thor

    class_option :debug, :type => :boolean

    def initialize(*args)
      super
      CircActivator::Log.create(options[:debug])
      @monitoring = CircActivator::Monitoring.new
    end

    desc 'update_group GROUP', 'Activate metrics for each check_bundle configured in GROUP'
    def update_group(group)
      unless CircActivator::Config['check_bundles'].include?(group)
        CircActivator::Log.fatal("Site #{group} not found in the configuration.")
        exit(1)
      end

      CircActivator::Config['check_bundles'][group].each do |check_bundle_id, regex|
        run_updater(group, check_bundle_id, regex)
      end

      exit_handler
    end

    desc 'update_all_groups', 'Activate all metrics for all check bundles in the configuration'
    def update_all_groups
      CircActivator::Config.check_bundles.each do |group, check_bundles|
        check_bundles.each do |check_bundle_id, regex|
          run_updater(group, check_bundle_id, regex)
        end
      end

      exit_handler
    end

    desc 'update_check_bundle CHECK_BUNDLE_ID [REGEX]', 'Activates all metrics for an arbitrary check bundle, activating only the metrics whose name match the optional regex'
    def update_check_bundle(check_bundle_id, regex=nil)
      run_updater('no_group', check_bundle_id, regex)
      exit_handler
    end

    no_commands do
      def run_updater(group, check_bundle_id, regex)
        CircActivator::Log.info("Starting update for group #{group}, check bundle #{check_bundle_id}")

        begin
          updater = CircActivator::CheckUpdater.new(check_bundle_id)
          updater.name_regex = regex unless regex.nil?
          updated_metrics = updater.run(options[:debug])
        rescue => e
          log_error("Error updating #{check_bundle_id}: #{e.class}: #{e.message}")
          return
        end

        if updated_metrics.length > 0
          CircActivator::Log.info("Update for group #{group}, check bundle #{check_bundle_id} complete.  Metrics added: #{updated_metrics.join(', ')}")
        else
          CircActivator::Log.info("Update for group #{group}, check bundle #{check_bundle_id} complete.  No metrics updated.")
        end
      end

      def log_error(msg)
        CircActivator::Log.error(msg)
        @monitoring.add_error_message(msg)
      end

      def exit_handler
        @monitoring.set_error_file unless options[:debug]
        if @monitoring.errors?
          Kernel.exit(2)
        else
          Kernel.exit(0)
        end
      end
    end
  end
end
