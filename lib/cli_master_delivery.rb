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
    All master files will be delivered to the "delivery root",
    but not the master snapshot directory itself.
    i.e. ~/my_snapshot_2e206ef3
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
    (defualt: MASTER_DIR/../backup)
  BACKUP
  VALUE_DELIVERY_TYPE = %w[symbolic_link regular_file].freeze
  DESC_DELIVERY_TYPE = <<~TYPE
    Delivery type. "#{VALUE_DELIVERY_TYPE.join('" or "')}" is accepted.
    Master files will be placed in the delivery root as
    symbolic links (ln -s) or regular files (cp).
    (default: #{VALUE_DELIVERY_TYPE[0]})
  TYPE
  DESC_DRYRUN = <<~DRYRUN
    Instead of actually moving or copying files, display
    the commands on stderr.
    (default: --no-dryrun)
  DRYRUN
  DESC_BANNER = <<~BANNER
    Deliver all master files you manage in one master snapshot directory to\
    the appropriate directories you specify, maintaining the master's directory hierarchy.
    If the file already exists, back it up and then put the master file.
      visit: https://github.com/shinyaohtani/master_delivery
  BANNER

  # command line wrapper
  class CliMasterDelivery
    attr_accessor :params

    def parse_options
      @params = { type: VALUE_DELIVERY_TYPE[0], dryrun: false }
      OptionParser.new do |opts|
        opts = define_options(opts)
        opts.parse!(ARGV, into: @params)
      end
    end

    def run
      @params.each { |param| p param }
      unless check_params
        puts 'See more with --help option'
        nil
      end

      # md = MasterDelivery::MasterDelivery.new(master_root, @params[:backup])
      # # md.deliver_files(master_id, @params[:delivery], dryrun: @params[:dryrun])
      # md.deliver_files(master_id, @params[:delivery], dryrun: true)
    end

    private

    def master_root
      File.dirname(File.expand_path(@params[:master]))
    end

    def master_id
      File.basename(File.expand_path(@params[:master]))
    end

    def define_options(opts) # rubocop:disable Metrics/AbcSize
      opts.version = VERSION
      opts.separator ' Required:'
      opts.on('-m [MASTER_DIR]',        '--master [MASTER_DIR]', *DESC_MASTER_DIR.split(/\R/)) { |v| v }
      opts.on('-d [DELIVERY_ROOT]',     '--delivery [DELIVERY_ROOT]', *DESC_DELIVERY_ROOT.split(/\R/)) { |v| v }
      opts.separator ''
      opts.separator ' Optional:'
      opts.on('-t [DELIVERY_TYPE]',     '--type [DELIVERY_TYPE]', *DESC_DELIVERY_TYPE.split(/\R/)) { |v| v }
      opts.on('-b [BABACKUP_ROOTCKUP]', '--backup [BACKUP_ROOT]', *DESC_BACKUP_ROOT.split(/\R/)) { |v| v }
      opts.on('-D',                     '--[no-]dryrun', *DESC_DRYRUN.split(/\R/)) { |v| v }
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
        #{DESC_BANNER}

        Usage: #{opts.program_name} -m <dir> -d <dir> [options]
      BANNER
      opts
    end

    def check_params
      check_param_master &&
        check_param_delivery &&
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
      elsif !File.directory?(@params[:delivery])
        puts "Invalid delivery root: #{@params[:delivery]}"
      else
        return true
      end
      false
    end

    def check_param_type
      return true if VALUE_DELIVERY_TYPE.include?(@params[:type])

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
