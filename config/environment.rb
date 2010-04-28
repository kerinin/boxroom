# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'activesupport'

Rails::Initializer.run do |config|
  # Customizing these configurations can be done here, by creating a file
  # at config/config.yml, or by setting environment variables
  # config.yml will be ignored by git, so it's a good place to put
  # sensitive data like S3 credentials or session keys
  CONFIG = {
    :paperclip => {
      :path => ":rails_root/uploads/:style/:id.:extension",
      :url => "/assets/:style/:id_:basename.:extension",
      :default_style => :original,
      :processors => [:thumbnail, :text_search],
      :styles => {
        #:original => {}#,
        :grid => "100x100>"
      }
    },
    :use_upload_progress => false,
    :searcher => :texticle, #:ferret,
    :email_from => 'Boxroom',
    :index_helpers =>  []
  }.deep_merge( 
    lambda { YAML.load_file('config/config.yml') rescue {} }.call 
  ).deep_merge(
    lambda { YAML.load( ENV['config_from_heroku']) rescue {} }.call
  ).merge(
    ENV
  )
  
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem "acts_as_ferret" if CONFIG[:searcher] == :ferret
  config.gem "rubyzip", :lib => 'zip/zip'
  config.gem "texticle"

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

