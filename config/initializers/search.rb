# config/initializers/load_config.rb
SEARCH_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/search.yml")[RAILS_ENV]

require SEARCH_CONFIG['require'] if SEARCH_CONFIG['require']

