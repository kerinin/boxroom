# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem "hoe", :version => '>=2.3.3'
  config.gem "acts_as_ferret"

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  
end

require 'configatron'

# Installation - specific configurations
# These values can be set on a per-environment basis
# by declaring them in /app/config/environments/yourenvironment.rb

configatron.paperclip = {
  :path => ":rails_root/uploads/:id",
  :url => "/assets/:style/:id_:basename.:extension",
  :default_style => :original,
  :processors => [:text_search],
  :styles => { 
    :original => {}                                   # <--- Necessary to trigger processors
    #:preview => '100x80#'
  }                                

  ## See http://dev.thoughtbot.com/paperclip/classes/Paperclip/Storage/S3.html
  ## for additional S3 Options    
  #:storage => s3                                      # <--- Uncomment to use Amazon S3 for storage
  #:s3_credentials => {
  # :access_key_id => 123...
  # :secret_access_key => 123...
  #:bucket => <mybucket>                               # <--- Change to your bucket name
}

# Use upload progress (or not)
configatron.use_upload_progress = false

## Search implementation [ :ferret | :texticle | none ]
configatron.searcher = :ferret

## To use texticle
## 1) $ rake texticle:migration && rake db:migrate
##
## To Use full-text search with texicle:
## 2) $ script/generate migration add_text_to_myfiles text:text && rake db:migrate
## 3) uncomment around line 15 of /app/models/myfile.rb
## 4) make sure the text_search paperclip processor is being used
#configatron.searcher = :texticle

# Email :from field
configatron.email_from = 'Boxroom'

# Define the helpers that extract the plain-text to be indexed
configatron.index_helpers = [ # defines helpers
  # Examples:
  #{ :ext => /rtf$/, :helper => 'unrtf --text %s', :remove_before => /-----------------/ },
  #{ :ext => /pdf$/, :helper => 'java -cp /Applications/PDFBox-0.7.3/lib/PDFBox-0.7.3-dev.jar:/Applications/PDFBox-0.7.3/external/FontBox-0.1.0-dev.jar org.pdfbox.ExtractText %s %s', :file_output => true },
  #{ :ext => /doc$/, :helper => 'antiword %s', :remove_before => /-----------------/ }
]


# ActionMailer config:
ActionMailer::Base.delivery_method = :smtp

ActionMailer::Base.smtp_settings = {
  :address => 'bogus',
  :port => 25,
  :domain => 'bogus'
}

