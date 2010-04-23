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
  config.gem "acts_as_ferret"
  #config.gem "texticle"

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

# ActionMailer config:
ActionMailer::Base.delivery_method = :smtp

ActionMailer::Base.smtp_settings = {
  :address => 'bogus',
  :port => 25,
  :domain => 'bogus'
}

# Use upload progress (or not)
USE_UPLOAD_PROGRESS = false

## Search implementation [ :ferret | :texticle | none ]
SEARCHER = :ferret

## To use texticle
## 1) uncomment the gem above
## 2) rake texticle:migration && rake db:migrate
## 3) comment out ferret, uncomment texticle
##
## To Use full-text search with texicle:
## 4) create a migration with 'add_column :myfiles, :text, :text'
## 5) uncomment around line 15 of /app/models/myfile.rb
## 6) make sure the text_search paperclip processor is being used
#SEARCHER = :texticle

# Email :from field
EMAIL_FROM = 'Boxroom'

# Define the helpers that extract the plain-text to be indexed
INDEX_HELPERS = [ # defines helpers
  # Examples:
  #{ :ext => /rtf$/, :helper => 'unrtf --text %s', :remove_before => /-----------------/ },
  #{ :ext => /pdf$/, :helper => 'java -cp /Applications/PDFBox-0.7.3/lib/PDFBox-0.7.3-dev.jar:/Applications/PDFBox-0.7.3/external/FontBox-0.1.0-dev.jar org.pdfbox.ExtractText %s %s', :file_output => true },
  #{ :ext => /doc$/, :helper => 'antiword %s', :remove_before => /-----------------/ }
]
