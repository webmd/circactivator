# CircActivator

CircActivator is a ruby application that will auto-activate (read: enable) metrics for Circnous check bundles.  It was written primarily for WebMD to auto-add NetScaler-related metrics gleaned from our internal NetScaler Web Service so our users would not have to do so manually every time they created a vserver.

The intent is for this to be a called as a scheduled task, a la cron.

## How To Use

### CLI

 * install the gem
 * create a `/etc/circactivator/circactivator.yml` config file
    * See the "Configuration" section below.
    * If you wish your config file to be somewhere else, you may point CircActivator to it using the `CIRCACTIVATORCONFIG` environment variable.
 * Run one of the commands:
    * `circactivator update_group GROUP` - updates a single group defined in the config
    * `circactivator update_all_groups` - updates all groups defined in the config
    * `circactivator update_check_bundle CHECK_BUNDLE_ID [REGEX]` - updates a single check bundle (which may or may not be defined in the config), and filter the metric names by REGEX (which is optional)

### In your own Ruby application

 * install the gem and require it accordingly
 * load the circactivator.yml config file:

```
config_file = '/path/to/config.yml'
CircActivator::Config.load_from_file(config_file)
```

 * Create a new instance of the CircActivator::CheckUpdater class and run it:

```
check_bundle_id = 123
updater = CircActivator::CheckUpdater.new(check_bundle_id)
updater.name_regex = /^my_metric_prefix/  # if you omit this method, it defaults to ".*"
updater.run
```

## Configuration

The configuration is a YAML file containing logging, monitoring, Circonus API, and check_bundle information.  Check bundles are grouped and each group can be updated individually by running the `update_group` circactivator command.

If you intend to use CircActivator from the command line, all sections and parameters of the config are required except the check_bundles section, though logically you must have one check_bundle group configured for CircActivator to be useful to you.  If you intend to use CircActivator from within your own application, only the circonus section is required.


```
log:
    file: /path/to/log/file/circactivator.log
    level: info
    count: 7

circonus:
    base_url: https://api.circonus.com/v2
    api_key: your-api-key-here
    api_app_name: circactivator

monitoring:
    error_file: /path/to/log/file/circactivator.err

check_bundles:
    iad1-prod:
        1: .*
        2: api-web
    iad1-nonprod:
        3: .*
        4: .*
```

### Log File

The `log` section of the config sets up the log file CircActivator uses to log information about each run.  When run with `--debug`, this log file is NOT used and log information is written to STDOUT.

### Circonus

The `circonus` section of the config specifies which Circonus instance to use (which is especially useful if you are a Circonus Inside customer) and your API key and app name.  See https://login.circonus.com/resources/api#authentication for more information.

### Monitoring

When not run in debug mode, CircActivator will write out an error file if any of the check_bundle updates were unsuccessful, and will remove this file after fully-successful invocation.  This is useful to monitor whenever CircActivator fails.  For example, you could use a nad script to set a metric to 1 whenever the error file exists and create a ruleset on that metric accordingly.

### Check Bundles

The `check_bundles` section is a hash containing group names which are arbitrary.  Each group name value is a hash: the key is the check_bundle ID, and the value is a regular expression.  CircScaler will only activate metrics that are currently in an "available" state and where the metric name matches regex.  In the example above, metrics in check bundle ID 2 will only be updated if the name includes the string "api-web".

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Author:: Adam Leff <aleff@webmd.net>

Copyright:: Copyright (c) WebMD, LLC

License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

```
http://www.apache.org/licenses/LICENSE-2.0
```

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
