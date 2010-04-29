module Paperclip
  class TextSearch < Paperclip::Processor
        
    def initialize(file, options = {}, attachment = nil, *args)
      @file = file
      @attachment = attachment
      @basename         = File.basename(@file.path) 
    end
  
    def self.handler original_filename
      case original_filename
      when /.txt$/
        lambda { File.open(original_filename) { |f| f.read } }
        
      when /.htm$|.html$/ # get the file, strip all <> tags
        lambda { File.open(original_filename) { |f| f.read.gsub(/<head>.*?<\/head>/m,'').gsub(/<.*?>/, ' ') } }

      when /.sxw$|.odt$/ # read content.xml from zip file, strip <> tags
        lambda {
          Zip::ZipFile.open(original_filename) do |zipfile|
            text_in_file = zipfile.file.open('content.xml') { |f| f.read.gsub(/<.*?>/, ' ') }
          end          
        }

      else
        matching_helpers = CONFIG[:index_helpers].map {|index_helper| 
          original_filename =~ index_helper[:ext] ? index_helper : nil 
        }.compact
        
        if matching_helpers
          index_helper = matching_helpers[-1]
          lambda {
            text_in_file = nil
            
            if index_helper[:file_output] # a file that writes to an output file
              `#{ sprintf(index_helper[:helper], @file.path, @file.path + '_copy') }`
              text_in_file = File.open(original_filename + '_copy') { |f| f.read }
              File.delete(original_filename + '_copy')
            else # we get the contents from stido directly
              text_in_file = `#{ sprintf(index_helper[:helper], @file.path) }`
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
        else
          nil
        end
      end
    end
    
    def make
      h = self.handler @attachment.original_filename
      @attachment.instance.index_file_contents h.call

      @file
    end
  end
end
