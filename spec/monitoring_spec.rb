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

describe CircActivator::Monitoring do
  before(:each) do
    @monitoring = CircActivator::Monitoring.new
  end

  it 'appends an error message' do
    @monitoring.add_error_message('my error')
    expect(@monitoring.error_messages).to eq(['my error'])
  end

  it 'errors? returns true when there are errors' do
    @monitoring.add_error_message('my error')
    expect(@monitoring.errors?).to eq(true)
  end

  it 'errors? returns false when there are no errors' do
    expect(@monitoring.errors?).to eq(false)
  end

  it 'writes out an error file if there are error messages' do
    expect(File).to receive(:write).with(CircActivator::Config.monitoring.error_file, 'my error')
    subject.add_error_message('my error')
    subject.set_error_file
  end

  it 'deletes the error file when there are no error messages' do
    expect(FileUtils).to receive(:rm_f).with(CircActivator::Config.monitoring.error_file)
    subject.set_error_file
  end
end
