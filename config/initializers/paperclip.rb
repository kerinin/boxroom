# Load from file
settings = YAML.load_file("#{RAILS_ROOT}/config/paperclip.yml")['all']

# Inject environment-specific settings
settings.merge!( settings[RAILS_ENV] ).symbolize_keys unless settings[RAILS_ENV].nil?

# Symbolize keys
PAPERCLIP_SETTINGS = settings.symbolize_keys


