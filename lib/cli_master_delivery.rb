#!/usr/bin/env ruby
# frozen_string_literal: true

# converter module from path to url
module MasterDelivery
  require 'master_delivery'
  require 'optparse'

  DESC_MASTER_DIR = <<~MASTER
    Master snapshot directory. All master files in this
    directory will be placed in the "delivery root",
    maintaining the directory structure.
    Only regular files will be delivered. That is,
    all symbolic link files and empty directories in
    MASTER_DIR are ignored.
  MASTER
  DESC_DELIVERY_ROOT = <<~DELIVERY
    Delivery root, or destination directory. All master
    files will be placed in this while maintaining the master
    directory structure.
  DELIVERY
  DESC_BACKUP_ROOT = <<~BACKUP
    Backup root, or Evacuation destination directory.
    All current active files will be moved into this
    directory maintaining the directory structure.
    Backup root will be created automatically. (mkdir -p)
     (defualt: MASTER_DIR/../backup)
  BACKUP
  VALUE_DELIVERY_TYPE = %w[symbolic_link regular_file].freeze
  DESC_DELIVERY_TYPE = <<~TYPE
    Delivery type. "#{VALUE_DELIVERY_TYPE.join('" or "')}" is accepted.
    Master files will be delivered as symbolic links (ln -s)
    or regular files (cp).
     (default: #{VALUE_DELIVERY_TYPE[0]})
  TYPE
  DESC_DRYRUN = <<~DRYRUN
    Instead of actually moving or copying files, display
    the commands on stderr.
    We strongly recommend "--dryrun" before running.
     (default: --no-dryrun)
  DRYRUN
  DESC_EXAMPLE = <<~EXAMPLE
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
  EXAMPLE

  # command line wrapper
  class CliMasterDelivery # rubocop:disable Metrics/ClassLength
    attr_accessor :params

    def initialize
      @params = { type: VALUE_DELIVERY_TYPE[0].to_sym, dryrun: false }
    end

    def parse_options
      OptionParser.new do |opts|
        opts = define_options(opts)
        opts.parse!(ARGV, into: @params)
      end
    end

    def run
      unless check_param_consistency
        puts 'See more with --help option'
        return
      end
      master_dir = File.expand_path(@params[:master])
      master_id = File.basename(master_dir)
      md = MasterDelivery.new(File.dirname(master_dir), @params[:backup])
      arg_set = [master_id, @params[:delivery]]
      arg_hash = { type: @params[:type], dryrun: @params[:dryrun] }
      return unless md.confirm(*arg_set, **arg_hash)

      md.deliver(*arg_set, **arg_hash)
    end

    private

    def define_options(opts) # rubocop:disable Metrics/AbcSize
      opts.version = VERSION
      opts.separator ' Required:'
      opts.on('-m [MASTER_DIR]',    '--master [MASTER_DIR]', *DESC_MASTER_DIR.split(/\R/)) { |v| v }
      opts.on('-d [DELIVERY_ROOT]', '--delivery [DELIVERY_ROOT]', *DESC_DELIVERY_ROOT.split(/\R/)) { |v| v }
      opts.separator ''
      opts.separator ' Optional:'
      opts.on('-t [DELIVERY_TYPE]', '--type [DELIVERY_TYPE]', *DESC_DELIVERY_TYPE.split(/\R/), &:to_sym)
      opts.on('-b [BACKUP_ROOT]',   '--backup [BACKUP_ROOT]', *DESC_BACKUP_ROOT.split(/\R/)) { |v| v }
      opts.on('-D',                 '--[no-]dryrun', *DESC_DRYRUN.split(/\R/)) { |v| v }
      opts.separator ''
      opts.separator ' Common options:'
      # opts.on('-v',    '--verbose', 'Verbose mode. default: no') { |v| v }
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
      opts.on_tail('-V', '--version', 'Show version') do
        puts opts.ver
        exit
      end
      opts.banner = <<~BANNER

        #{opts.ver}
        #{DESCRIPTION}
        #{DESC_EXAMPLE}
        Usage: #{opts.program_name} -m <dir> -d <dir> [options]
      BANNER
      opts
    end

    def check_param_consistency
      check_param_master &&
        check_param_delivery &&
        check_param_backup &&
        check_param_type &&
        check_param_argv
    end

    def check_param_master
      if @params[:master].nil?
        puts "Specify master snapshot directory by option '-m'"
      elsif !File.directory?(@params[:master])
        puts "Invalid master snapshot directory: #{@params[:master]}"
      else
        return true
      end
      false
    end

    def check_param_delivery
      if @params[:delivery].nil?
        puts "Specify delivery root by option '-d'"
        return false
      end
      master_dir = File.expand_path(@params[:master])
      delivery_root = File.expand_path(@params[:delivery])
      if delivery_root.start_with?(master_dir)
        puts <<~INCLUSION
          Invalid dirs. MASTER_DIR must not include DELIVERY_ROOT.
           MASTER_DIR:    #{master_dir}
           DELIVERY_ROOT: #{delivery_root}
        INCLUSION
        return false
      end
      true
    end

    def check_param_backup
      master_dir = File.expand_path(@params[:master])
      bkp = @params[:backup]
      if !bkp.nil? && !bkp.empty?
        backup_root = File.expand_path(bkp)
        if backup_root.start_with?(master_dir)
          puts <<~INCLUSION
            Invalid dirs. MASTER_DIR must not include BACKUP_ROOT.
             MASTER_DIR:  #{master_dir}
             BACKUP_ROOT: #{backup_root}
          INCLUSION
          return false
        end
      end
      true
    end

    def check_param_type
      return true if VALUE_DELIVERY_TYPE.include?(@params[:type].to_s)

      puts "Invalid delivery type: #{@params[:type]} (#{VALUE_DELIVERY_TYPE.join(' or ')})"
      false
    end

    def check_param_argv
      return true if ARGV.empty?

      puts "Invalid arguments are given: #{ARGV}"
      false
    end
  end
end
