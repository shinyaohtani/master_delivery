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
    Backup root will be created automatically. (mkdir -p)
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

  MSG_CONFIRMATION = <<~CONFIRMATION

    You can't undo this operation!
    Did you check that all parameters are correct? [yN]:
  CONFIRMATION

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
      md = MasterDelivery.new(File.dirname(master_dir), @params[:backup])
      return unless confirmation(md, master_dir)

      md.deliver(File.basename(master_dir), @params[:delivery],
                 type: @params[:type], dryrun: @params[:dryrun])
    end

    private

    def confirmation(deliv, master_dir)
      puts ''
      puts '** Important **'
      puts 'All master files inside MASTER_DIR will be delivered to inside DELIVER_ROOT'
      puts ''
      master_files = deliv.master_files(File.basename(master_dir))
      print_params(master_files)
      print_sample(deliv, master_dir, master_files)
      print MSG_CONFIRMATION.chomp # use print instead of puts for '\n'
      return true if gets.chomp == 'y'

      false
    end

    def print_sample(deliv, master_dir, master_files)
      master_id = File.basename(master_dir)
      sample_target = deliv.target_file_path(master_files[0], master_id, @params[:delivery])
      sample_backup = deliv.backup_file_path(master_files[0], master_id,
                                             deliv.backup_root + "/#{master_id}-original-XXXX")
      puts <<~SAMPLE

        Sample 1/#{master_files.size} is shown here:
        master:            #{master_files[0]}
        will be delivered: #{sample_target}
         and backup:       #{sample_backup}
      SAMPLE
    end

    def print_params(master_files)
      msg = "(-m) MASTER_DIR:   #{@params[:master]} (#{master_files.size} master files)\n"
      msg += "(-d) DELIVER_ROOT: #{@params[:delivery]}\n"
      msg += "(-t) DELIVER_TYPE: #{@params[:type]}\n"
      msg += if @params[:backup].nil? || @params[:backup].empty?
               "(-b) BACKUP_ROOT:  (default =[MASTER_DIR/../backup])\n"
             else
               "(-b) BACKUP_ROOT:  #{@params[:backup]}\n"
             end
      msg += "(-D) DRYRUN:       #{@params[:dryrun]}\n"
      puts msg
    end

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
        #{DESC_BANNER}

        Usage: #{opts.program_name} -m <dir> -d <dir> [options]
      BANNER
      opts
    end

    def check_param_consistency
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
      return true unless @params[:delivery].nil?

      puts "Specify delivery root by option '-d'"
      false
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
