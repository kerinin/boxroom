require 'mime/types'

module Paperclip
  class Preview < Paperclip::Thumbnail
    def self.handler original_filename
      case MIME::Types.type_for( original_filename ).to_s
      when 'image/jpeg', 'image/gif', 'image/png', 'image/tiff', 'image/x-ms-bmp', 'image/bmpimage/x-bmp'
        lambda { Paperclip::Thumbnail.make }
      # NOTE: PDF, Ai, & SVG parsing would be nice here...
      else
        nil
      end
    end
    
    def make
      self.handler.call original_filename
    end
  end
end

