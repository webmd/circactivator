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

require 'circactivator'
require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each) do
    CircActivator::Config.load_from_file(File.join(File.dirname(__FILE__), 'support', 'fixtures', 'config', 'config.yml'))
  end

  WebMock.disable_net_connect!(:allow_localhost => true)
end

def format_webmock_url(url)
  'https://api.circonus.com/v2' + url
end

def webmock_sample_file(filename)
  File.join(File.dirname(__FILE__), 'support', 'webmock', filename)
end
