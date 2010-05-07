module Paperclip
  class TextSearch < Paperclip::Processor
        
    def initialize(file, options = {}, attachment = nil, *args)
      @file = file
      @attachment = attachment
      @basename         = File.basename(@file.path) 
    end
  
    def self.handler filename
      basename = File.basename(filename)
      
      case basename
      when /.txt$/
        lambda { File.open(filename) { |f| f.read } }
        
      when /.htm$|.html$/ # get the file, strip all <> tags
        lambda { File.open(filename) { |f| f.read.gsub(/<head>.*?<\/head>/m,'').gsub(/<.*?>/, ' ') } }

      when /.sxw$|.odt$/ # read content.xml from zip file, strip <> tags
        lambda {
          Zip::ZipFile.open(filename) do |zipfile|
            text_in_file = zipfile.file.open('content.xml') { |f| f.read.gsub(/<.*?>/, ' ') }
          end          
        }

      else
        matching_helpers = CONFIG[:index_helpers].map {|index_helper| 
          basename =~ index_helper[:ext] ? index_helper : nil 
        }.compact
        
        return nil if matching_helpers.empty?
          
        index_helper = matching_helpers[-1]
        lambda { |file|
          text_in_file = nil
          
          if index_helper[:file_output] # a file that writes to an output file
            `#{ sprintf(index_helper[:helper], filename, filename + '_copy') }`
            text_in_file = File.open(filename + '_copy') { |f| f.read }
            File.delete(filename + '_copy')
          else # we get the contents from stido directly
            text_in_file = `#{ sprintf(index_helper[:helper], filename) }`
          end

          # Check if we need to remove first part (e.g. unrtf)
          unless index_helper[:remove_before].blank?
            if index_helper[:remove_before].match(text_in_file)
              text_in_file = Regexp::last_match.post_match 
            end
          end

          # Check if we need to remove last part
          unless index_helper[:remove_after].blank?
            if index_helper[:remove_after].match(text_in_file)
              text_in_file = Regexp::last_match.pre_match
            end
          end    
          
          return text_in_file        
        }
      end
    end
    
    def make
      h = TextSearch.handler @file.path #@attachment.original_filename
      @attachment.instance.index_file_contents h.call #(@file)

      @file
    end
  end
end
