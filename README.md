[![Gem Version](https://badge.fury.io/rb/master_delivery.svg)](https://badge.fury.io/rb/master_delivery)

# MasterDelivery

`MasterDelivery` is a master file manager utility. `MasterDelivery` delivers all master files managed in a single master snapshot directory into the specified directory while maintaining the hierarchy of the master snapshot directory. If the destination file already exists, back it up first and then deliver the master file.

**The difference with rsync** is that master_delivery creates a symlinks instead of copying the master files. They are symlinks, so you have to keep in mind that you have to keep the master files in the same location,
but it also has the advantage that the master file is updated at the same time when you directly make changes to the delivered file.

Do you have any experience that the master file is getting old gradually? master_delivery can prevent this.

If the master directory is git or svn managed, you can manage revisions of files that are delivered here and there at once with commands like git diff and git commit.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'master_delivery'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install master_delivery

## Usage

```
Example:
    If you specify MASTER_DIR and DELIVERY_ROOT as follows:
       MASTER_DIR:    -m ~/masters/my_home_setting
       DELIVERY_ROOT: -d /Users/foo

    and suppose master files in MASTER_DIR are as follows:
       ~/master/my_home_setting/.zshrc
       ~/master/my_home_setting/work/.rubocop.yml

    then these files will be delivered as the following files:
       /Users/foo/.zshrc
       /Users/foo/work/.rubocop.yml

Usage: master_delivery -m <dir> -d <dir> [options]
 Required:
    -m, --master [MASTER_DIR]        Master snapshot directory. All master files in this
                                     directory will be placed in the "delivery root",
                                     maintaining the directory structure.
                                     Only regular files will be delivered. That is,
                                     all symbolic link files and empty directories in
                                     MASTER_DIR are ignored.
    -d, --delivery [DELIVERY_ROOT]   Delivery root, or destination directory. All master
                                     files will be placed in this while maintaining the master
                                     directory structure.

 Optional:
    -t, --type [DELIVERY_TYPE]       Delivery type. "symbolic_link" or "regular_file" is accepted.
                                     Master files will be delivered as symbolic links (ln -s)
                                     or regular files (cp).
                                      (default: symbolic_link)
    -b, --backup [BACKUP_ROOT]       Backup root, or Evacuation destination directory.
                                     All current active files will be moved into this
                                     directory maintaining the directory structure.
                                     Backup root will be created automatically. (mkdir -p)
                                      (defualt: MASTER_DIR/../backup)
    -D, --[no-]dryrun                Instead of actually moving or copying files, display
                                     the commands on stderr.
                                     We strongly recommend "--dryrun" before running.
                                      (default: --no-dryrun)
    -y, --[no-]yes                   Skip confirmation. It is recommended to execute
                                     the command carefully without skipping confirmation.
                                     With the "--yes" option, if you want to change the
                                     command line argument even a little, remove the
                                     "--yes" option once, execute it several times,
                                     and experience confirmation several times.
                                     Also, it's a good idea to add the "--yes" option
                                     only after you start to feel confirmation annoying.
                                      (default: --no-yes)

 Common options:
    -h, --help                       Show this message
    -V, --version                    Show version

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/master_delivery. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/master_delivery/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MasterDelivery project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/master_delivery/blob/master/CODE_OF_CONDUCT.md).
