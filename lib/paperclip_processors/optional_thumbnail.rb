module Paperclip
  class OptionalThumbnail < Paperclip::Thumbnail
    attr_accessor :has_thumbnail
    
    def initialize(file, options = {}, attachment = nil, *args)
      super file, options, attachment, *args
      @has_thumbnail = attachment.instance.has_thumbnail?
    end

    def make
      if @has_thumbnail
        super
      else
        @file
      end
    end
  end
end
