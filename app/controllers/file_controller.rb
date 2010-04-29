require 'zip/zipfilesystem'

# The file controller contains the following actions:
# [#download]          downloads a file to the users system
# [#progress]          needed for upload progress
# [#upload]            shows the form for uploading files
# [#do_the_upload]     upload to and create a file in the database
# [#validate_filename] validates file to be uploaded
# [#rename]            show the form for adjusting the name of a file
# [#update]            updates the name of a file
# [#destroy]           delete files
# [#preview]           preview file; possibly with highlighted search words
class FileController < ApplicationController
  skip_before_filter :authorize, :only => :progress

  before_filter :does_folder_exist, :only => [:upload, :do_the_upload,] # if the folder DOES exist, @folder is set to it
  before_filter :does_file_exist, :except => [:upload, :progress, :do_the_upload, :validate_filename] # if the file DOES exist, @myfile is set to it
  before_filter :authorize_creating, :only => :upload
  before_filter :authorize_reading, :only => [:download, :preview]
  before_filter :authorize_updating, :only => [:rename, :update]
  before_filter :authorize_deleting, :only => :destroy

  session :off, :only => :progress

  # The requested file will be downloaded to the user's system.
  # Which user downloaded which file at what time will be logged.
  # (adapted from http://wiki.rubyonrails.com/rails/pages/HowtoUploadFiles)
  def download
    @style = ( params[:style] || 'original' ).to_sym
    
    # Log the 'usage' and return the file.
    usage = Usage.new
    usage.download_date_time = Time.now
    usage.user = @logged_in_user
    usage.myfile = @myfile
    usage.style = @style

    if usage.save
      if CONFIG[:paperclip][:storage] && CONFIG[:paperclip][:storage].to_sym == :s3
        send_data open( @myfile.attachment.url(@style) ).read, :filename => @myfile.attachment_file_name, :type => Mime::Type.lookup(@myfile.attachment.path(@style))
      else
        path = @myfile.attachment.path(@style)
        send_file path, :filename => File.basename(path), :type => Mime::Type.lookup(path)
      end
    end
  end

  # Shows upload progress.
  # For details, see http://mongrel.rubyforge.org/docs/upload_progress.html
  def progress
    render :update do |page|
      @status = Mongrel::Uploads.check(params[:upload_id])
      page.upload_progress.update(@status[:size], @status[:received]) if @status
    end
  end

  # Shows the form where a user can select a new file to upload.
  def upload
    @myfile = Myfile.new
    if CONFIG[:use_upload_progress]
      render
    else
      render :template =>'file/upload_without_progress'
    end
  end

  # Upload the file and create a record in the database.
  # The file will be stored in the 'current' folder.
  def do_the_upload
    @myfile = Myfile.new(params[:myfile])
    @myfile.folder_id = folder_id
    @myfile.user = @logged_in_user

    # change the filename if it already exists
    if CONFIG[:use_upload_progress] and not Myfile.find_by_filename_and_folder_id(@myfile.attachment_file_name, folder_id).blank?
      @myfile.attachement_file_name = @myfile.attachement_file_name + ' (' + Time.now.strftime('%Y%m%d%H%M%S') + ')' 
    end

    if @myfile.save
      if CONFIG[:use_upload_progress]
        return_url = url_for(:controller => 'folder', :action => 'list', :id => folder_id)
        render :text => %(<script type="text/javascript">window.parent.UploadProgress.finish('#{return_url}');</script>)
      else
        redirect_to :controller => 'folder', :action => 'list', :id => folder_id
      end
    else
      render :template =>'file/upload_without_progress' unless CONFIG['use_upload_progress']
    end
  end

  # Validates a selected file in a file field via an Ajax call
  def validate_filename
    filename = CGI::unescape(request.raw_post).chomp('=')
    filename = Myfile.base_part_of(filename)
    if Myfile.find_by_filename_and_folder_id(filename, folder_id).blank?
      render :text => %(<script type="text/javascript">document.getElementById('submit_upload').disabled=false;\nElement.hide('error');\nElement.hide('spinner');</script>)
    else
      render :text => %(<script type="text/javascript">document.getElementById('error').style.display='block';\nElement.hide('spinner');</script>\nThis file can not be uploaded, because it already exists in this folder.)
    end
  end

  # Expand archive into folders and files
  def expand   
    if @myfile.archive_root_elements_exist?
      flash[:folder_error] = "Expanding this archive would over-write existing files or folders"
      redirect_to :controller => 'folder', :action => 'list' and return false
    else
      begin
        @myfile.expand_archive
      rescue
        raise
        #flash[:folder_error] = 'There was a problem expanding the archive'
        redirect_to :controller => 'folder', :actions => 'list', :id => folder_id and return false
      else
        redirect_to :controller => 'folder', :action => 'list', :id => folder_id
      end
    end
  end
  
  # Show a form with the current name of the file in a text field.
  def rename
    render
  end

  # Update the name of the file with the new data.
  def update
    if request.post?
      if @myfile.update_attributes(:attachment_file_name => params[:myfile][:attachment_file_name], :attachment_updated_at => Time.now)
        redirect_to :controller => 'folder', :action => 'list', :id => folder_id
      else
        render_action 'rename'
      end
    end
  end

  # Preview file; possibly with highlighted search words.
  def preview
    if @myfile.indexed
      if params[:search].blank? # normal case
        @text = @myfile.text
      else # if we come from the search results page
        @text = @myfile.highlight(params[:search], { :field => :text, :excerpt_length => :all, :pre_tag => '[h]', :post_tag => '[/h]' })
      end
    end
  end

  # Delete a file.
  def destroy
    @myfile.destroy
    redirect_to :controller => 'folder', :action => 'list', :id => folder_id
  end

  # These methods are private:
  # [#does_file_exist] Check if a file exists before executing an action
  private
    # Check if a file exists before executing an action.
    # If it doesn't exist: redirect to 'list' and show an error message
    def does_file_exist
      @myfile = Myfile.find(params[:id])
    rescue
      flash.now[:folder_error] = 'Someone else deleted the file you are using. Your action was cancelled and you have been taken back to the root folder.'
      redirect_to :controller => 'folder', :action => 'list' and return false
    end
end
