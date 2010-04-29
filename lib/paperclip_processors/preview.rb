module Paperclip
  class Preview < Paperclip::Thumbnail
    attr_accessor :attachment
    
    def self.handler original_filename
      case Mime::Type.lookup original_filename
      when 'image/jpeg', 'image/gif', 'image/png', 'image/tiff', 'image/x-ms-bmp'
        lambda { Paperclip::Thumbnail.make }
      else
        nil
      end
    end
    
    def make
      self.handler.call original_filename
    end
  end
end

