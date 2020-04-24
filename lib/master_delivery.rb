# frozen_string_literal: true

require 'master_delivery/version'

# Deliver master files to appropriate place
module MasterDelivery
  require 'fileutils'
  require 'find'
  require 'tmpdir'

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
    # @param target_prefix [String] Files will be delivered to this prefix location.
    #   If this prefix is empty, it will be placed in the root directory.
    #   This mechanism saves you from having to unnecessarily deepen the directory
    #   hierarchy under master_id.
    #
    #   Example of prefix
    #     master_id: MID
    #     master: $master_root/MID/a/b/readme.md
    #     target_prefix: /Users/xxx/yyy
    #     delivery: /Users/xxx/yyy/a/b/readme.md
    #
    #   Example of no-prefix
    #     master_id: MID
    #     master: $master_root/MID/a/b/readme.md
    #     target_prefix: (empty)
    #     delivery: /a/b/readme.md
    #
    # @param type [symbol] only link (:symbolic_link) or copy master (:regular_file)
    # @param dryrun [boolean] if set this false, FileUtils::DryRun will be used.
    # note: Even if dryrun: true, @backup_dir is actually created! (for name-consistency)
    def deliver(master_id, target_prefix, type: :symbolic_link, dryrun: false)
      FileUtils.mkdir_p(@backup_root)
      utils = dryrun ? FileUtils::DryRun : FileUtils

      backup_dir = Dir.mktmpdir("#{master_id}-original-", @backup_root)
      master_files(master_id).each do |master|
        tfile = move_to_backup(master, utils, master_id, target_prefix, backup_dir)
        deliver_to_target(master, utils, tfile, type)
      end
      backup_dir
    end

    def master_files(master_id)
      Find.find("#{@master_root}/#{master_id}").select do |m|
        # Reject symbolic links.
        # Some "file?" And "symlink?" Do not work as requested
        # because they are determined after following a symbolic link.
        # "link.File.lstat" method does not follow symbolic links,
        # so you can check if it is a symbolic.
        File.lstat(m).file?
      end
    end

    def relative_master_path(master, master_id)
      File.expand_path(master).delete_prefix("#{@master_root}/#{master_id}")
    end

    def backup_file_path(master, master_id, backup_dir)
      File.expand_path(backup_dir) + relative_master_path(master, master_id)
    end

    def target_file_path(master, master_id, target_prefix)
      relative_master_path(master, master_id).prepend(File.expand_path(target_prefix))
    end

    private

    # Move a master file currently used to backup/
    def move_to_backup(master, utils, master_id, target_prefix, backup_dir)
      backupfiledir = File.dirname(backup_file_path(master, master_id, backup_dir))
      utils.mkdir_p(backupfiledir)
      tfile = target_file_path(master, master_id, target_prefix)
      utils.mv(tfile, backupfiledir, force: true)
      tfile
    end

    # Deliver a link to a master (or a copy of a master) in the appropriate directory
    def deliver_to_target(master, utils, tfile, type)
      tfiledir = File.dirname(tfile)
      utils.mkdir_p(tfiledir)
      case type
      when :symbolic_link
        utils.ln_s(master, tfiledir)
      when :regular_file
        utils.cp(master, tfiledir)
      end
    end
  end
end
