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
    def deliver_files(master_id, target_prefix, type: :symbolic_link, dryrun: false)
      utils = dryrun ? FileUtils::DryRun : FileUtils

      backup_dir = Dir.mktmpdir("#{master_id}-original-", @backup_root)
      Find.find("#{@master_root}/#{master_id}") do |master|
        next unless File::Stat.new(master).file?

        tfile = move_to_backup(master, utils, master_id, target_prefix, backup_dir)
        deliver_to_target(master, utils, tfile, type)
      end
      backup_dir
    end

    def master_files(master_id)
      Find.find("#{@master_root}/#{master_id}").reject{!File::Stat.new(master).file?}
    end

    private

    # Move a master file currently used to backup/
    def move_to_backup(master, utils, master_id, target_prefix, backup_dir)
      relative_master = master.delete_prefix("#{@master_root}/#{master_id}")
      backupfiledir = File.dirname(backup_dir + relative_master)
      utils.mkdir_p(backupfiledir)
      tfile = relative_master.prepend(target_prefix)
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
