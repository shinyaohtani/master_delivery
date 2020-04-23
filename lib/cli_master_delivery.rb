#!/usr/bin/env ruby
# frozen_string_literal: true

# converter module from path to url
module MasterDelivery
  require 'master_delivery'
  require 'optparse'

  DESC_MASTER_DIR = <<~MASTER
    Master snapshot directory. All master files in this directory
    will be placed in the "delivery root", maintaining the directory structure.
    All master files will be delivered to the "delivery root", but
    not the master snapshot directory itself. i.e. ~/my_snapshot_2e206ef3'
  MASTER
  DESC_DELIVERY_ROOT = <<~DELIVERY
    Delivery root, or destination directory. All master files will
    be placed in this while maintaining the master directory structure.
  DELIVERY
  DESC_BACKUP_ROOT = <<~BACKUP
    Backup root, or Evacuation destination directory. All current active files
    will be moved into this directory maintaining the directory structure.
  BACKUP
  DESC_DELIVERY_TYPE = <<~TYPE
    Delivery type. "symbolic_link" or "regular_file" is accepted.
    Master files will be placed in the delivery root as
    symbolic links (ln -s) or regular files (cp). Default is symbolic_link.
  TYPE
  DESC_DRYRUN = <<~DRYRUN
    Instead of actually moving or copying files, display the commands on stderr.
  DRYRUN

  # command line wrapper
  class CliMasterDelivery
    attr_accessor :params

    def parse_options
      @params = {}
      OptionParser.new do |opts|
        opts = define_options(opts)
        opts.parse!(ARGV, into: @params)
      end
    end

    def run
      unless check_params
        puts 'See more with --help option'
        return
      end

      md = if @params[:backup].nil?
             MasterDelivery::MasterDelivery.new(master_root)
           else
             MasterDelivery::MasterDelivery.new(master_root, backup_root)
           end
      dryrun = !@params[:dryrun].nil?
      md.deliver_files(master_id, delivery_root, dryrun: true)
    end

    private

    def master_root
      File.dirname(File.expand_path(@params[:master]))
    end

    def master_id
      File.basename(File.expand_path(@params[:master]))
    end

    def delivery_root
      File.expand_path(@params[:delivery])
    end

    def backup_root
      File.expand_path(@params[:backup])
    end

    def define_options(opts) # rubocop:disable Metrics/AbcSize
      opts.version = VERSION
      opts.on('-m [MASTER_DIR]', '--master [MASTER_DIR]', DESC_MASTER_DIR) { |v| v }
      opts.on('-d [DELIVERY_ROOT]', '--delivery [DELIVERY_ROOT]', DESC_DELIVERY_ROOT) { |v| v }
      opts.on('-t [DELIVERY_TYPE]', '--type [DELIVERY_TYPE]', DESC_DELIVERY_TYPE) { |v| v }
      opts.on('-b [BABACKUP_ROOTCKUP]', '--backup [BACKUP_ROOT]', DESC_BACKUP_ROOT) { |v| v }
      opts.on('-D',            '--dryrun', DESC_DRYRUN) { |v| v }
      # opts.on('-v',            '--verbose', 'Verbose mode. default: no') { |v| v }
      opts.on_tail('-h',       '--help', 'Show this message') do
        puts opts
        exit
      end
      opts.on_tail('-V', '--version', 'Show version') do
        puts opts.ver
        exit
      end
      opts.banner = <<~BANNER

        #{opts.ver}
        Deliver all master files you manage in one master snapshot directory to\
        the appropriate directories you specify, maintaining the master's directory hierarchy.
        If the file already exists, back it up and then put the master file.
          visit: https://github.com/shinyaohtani/master_delivery

        Usage: #{opts.program_name} [options] -m <dir> -d <dir> [-t <type>] [-b <dir>]
         [options]:
      BANNER
      opts
    end

    def check_params # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      valid = false
      if @params[:master].nil?
        puts "Specify master snapshot directory by option '-m'"
      elsif !File.directory?(@params[:master])
        puts "Invalid master snapshot directory: #{@params[:master]}"
      elsif @params[:delivery].nil?
        puts "Specify delivery root by option '-d'"
      elsif !File.directory?(@params[:delivery])
        puts "Invalid delivery root: #{@params[:delivery]}"
      elsif @params[:type].nil?
        puts "Specify delivery type by option '-t'"
      elsif !%w[symbolic_link regular_file].include?(@params[:type])
        puts "Invalid delivery type: #{@params[:type]} (symbolic_link or regular_file)"
      else
        valid = true
      end
      valid
    end
  end
end
