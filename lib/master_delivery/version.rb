# frozen_string_literal: true

module MasterDelivery
  VERSION = '1.0.7'
  DESCRIPTION = <<~DESC
    Deliver all master files managed in a single master snapshot directory
    into the specified directory while maintaining the hierarchy of the
    master snapshot directory. If the destination file already exists,
    back it up first and then deliver the master file.

    The difference with rsync is that master_delivery creates a symlinks
    instead of copying the master files. They are symlinks, so you have to
    keep in mind that you have to keep the master files in the same location,
    but it also has the advantage that the master file is updated at the same
    time when you directly make changes to the delivered file.

    Do you have any experience that the master file is getting old gradually?
    master_delivery can prevent this.

    If the master directory is git or svn managed, you can manage revisions
    of files that are delivered here and there at once with commands
    like git diff and git commit.
  DESC
  REPOSITORY_URL = 'https://github.com/shinyaohtani/master_delivery'
end
