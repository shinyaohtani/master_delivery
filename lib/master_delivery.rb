# frozen_string_literal: true

require 'master_delivery/version'

# Deliver master files to appropriate place
module MasterDelivery
  require 'fileutils'
  require 'find'

  class Error < StandardError; end

  # File delivery class
  # 1. Move the current active files to tmp/
  # 2. Place a symbolic link to the master (or copy of master) in the appropriate directory
  #
  class MasterDelivery
    # @param master_root [String] Path to the directory including master dirs.
    def initialize(master_root)
      @master_root = File.expand_path(master_root)
      @unique_string = Time.now.strftime('%Y-%m-%d+%H-%M-%S')
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
    def deliver_files(master_id, target_prefix, type: :symbolic_link, dryrun: false)
      utils = dryrun ? FileUtils::DryRun : FileUtils

      tmpdir = "#{@master_root}/tmp/#{master_id}-original-#{@unique_string}"
      utils.rmtree(tmpdir, secure: true)
      utils.mkdir_p(tmpdir)

      Find.find("#{@master_root}/#{master_id}") do |master|
        next unless File::Stat.new(master).file?

        tfile = move_to_tmp(master, utils, tmpdir, master_id, target_prefix)
        deliver_to_target(master, utils, tfile, type)
      end
    end

    private

    # Move a master file currently used to tmp/
    def move_to_tmp(master, utils, tmpdir, master_id, target_prefix)
      relative_master = master.delete_prefix("#{@master_root}/#{master_id}")
      tmpfiledir = File.dirname(tmpdir + relative_master)
      utils.mkdir_p(tmpfiledir)
      tfile = relative_master.prepend(target_prefix)
      utils.mv(tfile, tmpfiledir, force: true)
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
