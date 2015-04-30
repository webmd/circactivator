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

describe CircActivator::CLI do
  before(:each) do
    allow(CircActivator::Log).to receive(:debug)
    allow(CircActivator::Log).to receive(:error)

    @monitoring = CircActivator::Monitoring.new
    allow(CircActivator::Monitoring).to receive(:new).and_return(@monitoring)
    allow(@monitoring).to receive(:add_error_message)
    allow(@monitoring).to receive(:set_error_file)
  end

  it 'calls run_updater for a single group' do
    expect(subject).to receive(:run_updater).with('iad1-prod', 1, '.*')
    expect(subject).to receive(:run_updater).with('iad1-prod', 2, 'api-web')
    expect(subject).to receive(:exit_handler)
    subject.update_group('iad1-prod')
  end

  it 'calls run_updater for all groups and check_bundles in the config' do
    expect(subject).to receive(:run_updater).with('iad1-prod', 1, '.*')
    expect(subject).to receive(:run_updater).with('iad1-prod', 2, 'api-web')
    expect(subject).to receive(:run_updater).with('iad1-nonprod', 3, '.*')
    expect(subject).to receive(:run_updater).with('iad1-nonprod', 4, '.*')
    expect(subject).to receive(:exit_handler)
    subject.update_all_groups
  end

  it 'runs a single CheckUpdater when update_check_bundle is called - no regex passed' do
    updater = CircActivator::CheckUpdater.new(333)
    expect(CircActivator::CheckUpdater).to receive(:new).with(333).and_return(updater)
    expect(updater).to_not receive(:name_regex=)
    expect(updater).to receive(:run).and_return([])
    expect(subject).to receive(:exit_handler)
    subject.update_check_bundle(333)
  end

  it 'runs a single CheckUpdater when update_check_bundle is called - regex passed' do
    updater = CircActivator::CheckUpdater.new(333)
    expect(CircActivator::CheckUpdater).to receive(:new).with(333).and_return(updater)
    expect(updater).to receive(:name_regex=).with('myfilter')
    expect(updater).to receive(:run).and_return([])
    expect(subject).to receive(:exit_handler)
    subject.update_check_bundle(333, 'myfilter')
  end

  it 'configures a CircActivator::CheckUpdater instance correctly with regex' do
    updater = CircActivator::CheckUpdater.new(1)
    expect(CircActivator::CheckUpdater).to receive(:new).and_return(updater)
    expect(updater).to receive(:name_regex=).with('test.*name')
    expect(updater).to receive(:run).and_return([])

    subject.run_updater('group', 1, 'test.*name')
  end

  it 'appends an error message when run_updater raises an exception' do
    updater = CircActivator::CheckUpdater.new(1)
    expect(CircActivator::CheckUpdater).to receive(:new).and_return(updater)
    expect(updater).to receive(:run).and_raise(CircActivator::Exception::CirconusError)
    expect(subject).to receive(:log_error)

    subject.run_updater('group', 1, '.*')
  end

  it 'log_error calls add_error_message and logs an error' do
    expect(@monitoring).to receive(:add_error_message).with('my error')
    expect(CircActivator::Log).to receive(:error).with('my error')
    subject.log_error('my error')
  end

  context 'exit_handler' do
    before(:each) do
      allow(Kernel).to receive(:exit).with(0)
      allow(Kernel).to receive(:exit).with(2)
    end

    it 'exits 0 when there are no errors' do
      expect(Kernel).to receive(:exit).with(0)
      subject.exit_handler
    end

    it 'exits 2 where there is an error' do
      @monitoring.add_error_message('dummy error')
      subject.exit_handler
    end

    it 'calls set_error_file by default' do
      @monitoring.add_error_message('dummy error')
      expect(@monitoring).to receive(:set_error_file)
      subject.exit_handler
    end

    it 'does not call set_error_file when in debug mode' do
      @monitoring.add_error_message('dummy error')
      expect(@monitoring).to_not receive(:set_error_file)
      subject.options = { debug: true }
      subject.exit_handler
    end
  end
end
