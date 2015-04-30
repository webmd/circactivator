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

module CircActivator
  class Monitoring

    attr_reader :error_messages
    
    def initialize
      @error_messages = Array.new
    end

    def add_error_message(msg)
      @error_messages << msg
    end

    def errors?
      @error_messages.length > 0
    end

    def set_error_file
      if errors?
        File.write(CircActivator::Config.monitoring.error_file, @error_messages.join("\n"))
        true
      else
        FileUtils.rm_f(CircActivator::Config.monitoring.error_file)
        false
      end
    end
  end
end
