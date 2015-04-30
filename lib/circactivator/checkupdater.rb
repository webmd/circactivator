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

require 'httparty'
require 'json'

module CircActivator
  class CheckUpdater

    attr_reader :check_bundle
    attr_accessor :name_regex
    
    def initialize(check_bundle_id)
      @check_bundle_id = check_bundle_id
      @check_bundle    = Hash.new
      @name_regex      = '.*'
    end

    def http_headers
      {
        'X-Circonus-Auth-Token' => CircActivator::Config.circonus.api_key,
        'X-Circonus-App-Name'   => CircActivator::Config.circonus.api_app_name,
        'Accept'                => 'application/json'
      }
    end

    def url
      CircActivator::Config.circonus.base_url + '/check_bundle/' + @check_bundle_id.to_s
    end

    def fetch
      response = HTTParty.get(url + '?query_broker=1', headers: http_headers, verify: false)
      raise_exceptions!(response)
      @check_bundle = JSON.load(response.body)
    end

    def activate_metrics
      return if @check_bundle['metrics'].nil?
      updated_metrics = Array.new
      @check_bundle['metrics'].select {
        |metric| metric['status'] == 'available' && metric['name'] =~ /#{self.name_regex}/
      }.each do |metric|
        updated_metrics << metric['name']
        metric['status'] = 'active'
      end
      updated_metrics
    end

    def payload_hash
      @check_bundle.select { |k,v| k =~ /brokers|config|display_name|metrics|notes|period|status|tags|target|timeout|type/ }
    end

    def update
      response = HTTParty.put(url, headers: http_headers, body: payload_hash.to_json, verify: false)
      raise_exceptions!(response)
    end

    def raise_exceptions!(response)
      case response.code.to_s
      when /^2/
        return
      when '404'
        raise CircActivator::Exception::CheckNotFound, "Check bundle ID #{@check_bundle_id} not found"
      else
        raise CircActivator::Exception::CirconusError, 
          "Server error when handling check bundle #{@check_bundle_id}: #{response.body}"
      end
    end

    def run(logging=false)
      fetch
      updated_metrics = activate_metrics
      update
      
      updated_metrics
    end
  end
end
