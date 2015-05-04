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

require 'spec_helper'

describe CircActivator::CheckUpdater do
  let(:check_bundle_id) { 123 }
  let(:updated_metrics_all) {
    %w( vserver1:80`actsvcs
        vserver1:80`curclntconnections
        vserver1:80`cursrvrconnections
        vserver1:80`inactsvcs
        vserver1:80`totalrequestbytes
        vserver1:80`totalrequests
        vserver1:80`totalresponsebytes
        vserver1:80`totalresponses
        vserver1:80`tothits
        vserver1:80`vslbhealth
    )
  }
  let(:updated_metrics_with_regex) {
    %w( vserver1:80`actsvcs
        vserver1:80`inactsvcs
    )
  }

  before(:each) do
    @checkupdater = CircActivator::CheckUpdater.new(check_bundle_id)
  end

  it 'returns http headers' do
    expect(@checkupdater.http_headers['X-Circonus-Auth-Token']).to eq('a12345')
    expect(@checkupdater.http_headers['X-Circonus-App-Name']).to eq('my_app')
  end

  it 'returns a check bundle URL' do
    expect(@checkupdater.url).to eq("https://api.circonus.com/v2/check_bundle/123")
  end

  it 'raises an exception if the check is not found' do
    stub_request(:get, format_webmock_url("/check_bundle/#{check_bundle_id}?query_broker=1")).to_return(status: 404)
    expect { @checkupdater.fetch }.to raise_error(CircActivator::Exception::CheckNotFound)
  end

  it 'raises an exception if the status code is not 200 or 404' do
    stub_request(:get, format_webmock_url("/check_bundle/#{check_bundle_id}?query_broker=1")).to_return(status: 500)
    expect { @checkupdater.fetch }.to raise_error(CircActivator::Exception::CirconusError)
  end

  it 'activate_metrics returns nil when check_bundle is empty' do
    expect(@checkupdater.activate_metrics).to eq(nil)
  end

  context 'check with data' do
    before(:each) do
      stub_request(:get, format_webmock_url("/check_bundle/#{check_bundle_id}?query_broker=1")).
        to_return(:status => 200, :body => File.read(webmock_sample_file('lbvserver_check_bundle.json')))
      stub_request(:put, format_webmock_url("/check_bundle/#{check_bundle_id}")).to_return(status: 201)

      @checkupdater = CircActivator::CheckUpdater.new(check_bundle_id)
      @checkupdater.fetch
    end

    it 'fetches a check' do
      expect(@checkupdater.check_bundle.size).to be > 0
      expect(@checkupdater.check_bundle.include?('_cid')).to eq(true)
      expect(@checkupdater.check_bundle.include?('metrics')).to eq(true)
    end

    it 'activates the appropriate list of metrics - .* regex as default' do
      expect(@checkupdater.activate_metrics.sort).to eq(updated_metrics_all.sort)
    end

    it 'activates the appropriate list of metrics - svcs regex' do
      @checkupdater.name_regex = 'svcs'
      expect(@checkupdater.activate_metrics.sort).to eq(updated_metrics_with_regex.sort)
    end

    it 'returns a payload hash containing the necessary fields' do
      expect(@checkupdater.payload_hash.keys.sort).to eq([
        'brokers',
        'config',
        'display_name',
        'metrics',
        'notes',
        'period',
        'status',
        'tags',
        'target',
        'timeout',
        'type'
      ])
      expect(@checkupdater.payload_hash['metrics'].length).to be > 0
    end

    it 'updates the check' do
      expect { @checkupdater.update }.to_not raise_error
    end

    it 'calls the right methods during the run' do
      expect(@checkupdater).to receive(:fetch)
      expect(@checkupdater).to receive(:activate_metrics).and_return(['metric1', 'metric2'])
      expect(@checkupdater).to receive(:update)
      @checkupdater.run
    end

    it 'does not call update when no metrics are returned' do
      expect(@checkupdater).to receive(:activate_metrics).and_return([])
      expect(@checkupdater).to_not receive(:update)
      @checkupdater.run
    end
  end
end
