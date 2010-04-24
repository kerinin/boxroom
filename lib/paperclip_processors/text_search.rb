module Paperclip
  class TextSearch < Paperclip::Processor
        
    def initialize(file, options = {}, attachment = nil, *args)
      @file = file
      @attachment = attachment
      @basename         = File.basename(@file.path) 
    end
  
    def make
      # Variable to hold the plain text content of the uploaded file
      text_in_file = nil
      
      # Try to get the text from the uploaded file
      case @basename
        when /.txt$/
          text_in_file = @file.read

        when /.htm$|.html$/ # get the file, strip all <> tags
          text_in_file = @file.read.gsub(/<head>.*?<\/head>/m,'').gsub(/<.*?>/, ' ')

        when /.sxw$|.odt$/ # read content.xml from zip file, strip <> tags
          Zip::ZipFile.open(@file.path) do |zipfile|
            text_in_file = zipfile.file.open('content.xml') { |f| f.read.gsub(/<.*?>/, ' ') }
          end
        else
          text_in_file = 'FAIL!'
      end

      # If it didn't get caught yet, try the helpers
      if text_in_file.blank?
        INDEX_HELPERS.each do |index_helper| # defined in environment.rb
          if @basename =~ index_helper[:ext] # a matching helper!   

            if index_helper[:file_output] # a file that writes to an output file
              `#{ sprintf(index_helper[:helper], @file.path, @file.path + '_copy') }`
              text_in_file = File.open(@file.path + '_copy') { |f| f.read }
              File.delete(@file.path + '_copy')
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
          end
        end
      end

      @attachment.instance.index_file_contents text_in_file

      @file
    end
  end
end
