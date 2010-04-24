namespace :heroku do
  desc "Creates heroku config vars out of config/config.yml"
  task :config do
    puts "Reading config/config.yml and sending config vars to Heroku..."
    CONFIG = YAML.load_file('config/config.yml') rescue {}
    command = "heroku config:add config_from_heroku='#{YAML.dump_stream CONFIG}'"
    system command
  end
end
