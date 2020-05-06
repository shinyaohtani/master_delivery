# frozen_string_literal: true

require 'master_delivery/version'

# Deliver master files to appropriate place
module MasterDelivery
  require 'fileutils'
  require 'find'
  require 'pathname'
  require 'tmpdir'
  MSG_CONFIRMATION_INTRO = <<~CONFIRM_INTRO

    ** Important **
    You can't undo this operation!

  CONFIRM_INTRO
  MSG_CONFIRMATION = <<~CONFIRMATION

    Did you check that all parameters are correct? [yN]:
  CONFIRMATION

  # File delivery class
  # 1. Move the current active files to backup/
  # 2. Place a symbolic link to the master (or copy of master) in the appropriate directory
  #
  class MasterDelivery
    attr_reader :backup_root
    # @param master_root [String] Path to the dir including master dirs.
    # @param backup_root [String] Path to the dir in which backup masters are created.
    def initialize(master_root, backup_root = '')
      @master_root = File.expand_path(master_root)
      @backup_root = if backup_root.nil? || backup_root.empty?
                       File.expand_path(master_root + '/backup')
                     else
                       File.expand_path(backup_root)
                     end
    end

    # @param master_id [String] Top directory name of master
    #
    # @param delivery_root [String] Files will be delivered to this prefix location.
    #   If this prefix is empty, it will be placed in the root directory.
    #   This mechanism saves you from having to unnecessarily deepen the directory
    #   hierarchy under master_id.
    #
    #   Example of prefix
    #     master_id: MID
    #     master: $master_root/MID/a/b/readme.md
    #     delivery_root: /Users/xxx/yyy
    #     delivery: /Users/xxx/yyy/a/b/readme.md
    #
    #   Example of no-prefix
    #     master_id: MID
    #     master: $master_root/MID/a/b/readme.md
    #     delivery_root: (empty)
    #     delivery: /a/b/readme.md
    #
    # @param type [symbol] only link (:symbolic_link) or copy master (:regular_file)
    # @param dryrun [boolean] if set this false, FileUtils::DryRun will be used.
    # note: Even if dryrun: true, @backup_dir is actually created! (for name-consistency)
    def deliver(basics, type: :symbolic_link, dryrun: false, verbose: false)
      FileUtils.mkdir_p(@backup_root)
      utils = dryrun ? FileUtils::DryRun : FileUtils

      backup_dir = Dir.mktmpdir("#{basics[:master_id]}-original-", @backup_root)
      puts "mkdir -p #{backup_dir}" if verbose
      mfiles = master_files(basics[:master_id])
      mfiles.each do |master|
        tfile = move_to_backup(master, utils, basics, backup_dir, verbose)
        deliver_to_target(master, utils, tfile, type, verbose)
      end
      [mfiles, backup_dir]
    end

    # @param params [Hash] :type, :dryrun, :yes, :quiet
    def confirm(basics, params)
      unless params[:quiet]
        puts MSG_CONFIRMATION_INTRO unless params[:yes]
        print_params(basics, params.slice(:type, :dryrun))
        print_sample(basics)
      end
      print MSG_CONFIRMATION.chomp unless params[:yes] # use print instead of puts for '\n'
      return true if params[:yes] || gets.chomp == 'y'

      puts 'aborted.'
      false
    end

    private

    # Move a master file currently used to backup/
    def move_to_backup(master, utils, basics, backup_dir, verbose)
      backupfiledir = File.dirname(backup_file_path(master, basics[:master_id], backup_dir))
      utils.mkdir_p(backupfiledir, verbose: verbose)
      tfile = target_file_path(master, basics)
      utils.mv(tfile, backupfiledir, force: true, verbose: verbose)
      tfile
    end

    # Deliver a link to a master (or a copy of a master) in the appropriate directory
    def deliver_to_target(master, utils, tfile, type, verbose)
      tfiledir = File.dirname(tfile)
      utils.mkdir_p(tfiledir, verbose: verbose)
      case type
      when :symbolic_link
        utils.ln_s(master, tfiledir, verbose: verbose)
      when :regular_file
        utils.cp(master, tfiledir, verbose: verbose)
      end
    end

    # @param params [Hash] :type, :dryrun
    def print_params(basics, params)
      mfiles = master_files(basics[:master_id])
      msg =  "(-m) MASTER_DIR:   -m #{@master_root}/#{basics[:master_id]} (#{mfiles.size} master files)\n"
      msg += "(-d) DELIVER_ROOT: -d #{File.expand_path(basics[:delivery_root])}\n"
      msg += "(-t) DELIVER_TYPE: -t #{params[:type]}\n"
      msg += "(-b) BACKUP_ROOT:  -b #{@backup_root}\n"
      msg += "(-D) DRYRUN:       #{params[:dryrun] ? '--dryrun' : '--no-dryrun'}\n"
      puts msg
    end

    def print_sample(basics)
      mfiles = master_files(basics[:master_id])
      sample_target = target_file_path(mfiles[0], basics)
      sample_backup = backup_file_path(mfiles[0], basics[:master_id],
                                       @backup_root + "/#{basics[:master_id]}-original-XXXX")
      puts <<~SAMPLE

        Sample (from #{mfiles.size} master files):
        master:            #{mfiles[0]}
        will be delivered: #{sample_target}
         and backup:       #{sample_backup}
      SAMPLE
    end

    def master_files(master_id)
      Find.find("#{@master_root}/#{master_id}").select do |m|
        # Reject symbolic links.
        # Some "file?" and "symlink?" mothods do not work as requested
        # because they are determined after following a symbolic link.
        # "link.File.lstat" method does not follow symbolic links,
        # so you can check if it is a symbolic or not.
        File.lstat(m).file?
      end
    end

    def relative_master_path(master, master_id)
      File.expand_path(master).delete_prefix("#{@master_root}/#{master_id}")
    end

    def backup_file_path(master, master_id, backup_dir)
      path = File.expand_path(backup_dir) + relative_master_path(master, master_id)
      Pathname.new(path).cleanpath.to_s
    end

    def target_file_path(master, basics)
      path = relative_master_path(master, basics[:master_id]).prepend(File.expand_path(basics[:delivery_root]))
      Pathname.new(path).cleanpath.to_s
    end
  end
end
