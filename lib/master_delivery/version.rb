# frozen_string_literal: true

module MasterDelivery
  VERSION = '1.0.2'
  DESCRIPTION = <<~DESC
    Deliver all master files managed in a single master snapshot directory
    into the specified directory while maintaining the hierarchy of the
    master snapshot directory. If the destination file already exists,
    back it up first and then deliver the master file.
  DESC
end
