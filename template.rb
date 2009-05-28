PROJECT = root.split("/")[-1]

gem 'mislav-will_paginate', :lib => 'will_paginate', :source => 'http://gems.github.com'
gem 'ambethia-smtp-tls', :lib => 'smtp-tls', :source => "http://gems.github.com"
gem 'sqlite3-ruby', :lib => 'sqlite3'

rake "gems:install", :sudo => true

# Delete unnecessary files
run "rm README"
run "rm public/index.html"
run "rm public/favicon.ico"
run "rm public/robots.txt"
run "rm -f public/javascripts/*"

file 'README.md', <<README
#{PROJECT.humanize}
#{"-" * PROJECT.size}

README

file '.gitignore', <<IGNORE
.DS_Store
log/*.log
tmp/**/*
config/database.yml
config/initializers/action_mailer_configs.rb
db/*.sqlite3
IGNORE

capify!

file 'config/deploy.rb' do
  host = ask "\nServer to deploy to?"
  <<-END
  default_run_options[:pty] = true
  
  set :use_sudo, false
  
  set :ssh_options, { :forward_agent => true }
  set :domain, "#{host}"
  
  set :application, "#{PROJECT}"
  set :repository,  "git@github.com:#{`whoami`.chomp}/#{PROJECT}.git"
  set :deploy_to, "/var/www/#{PROJECT}"
  set :scm, :git
  set :git_enable_submodules, 1
  set :deploy_via, :remote_cache
  set :git_shallow_clone, 1
  
  set :group, "www-data"
  
  role :app, domain
  role :web, domain
  role :db,  domain, :primary => true
  
  namespace :deploy do
    %w|start restart|.each do |t|
      task t do
        run "touch #{"#"}{current_path}/tmp/restart.txt"
      end
    end
  end
  
  desc "Link production files"
  task :after_symlink do
    run "ln -nfs #{"#"}{shared_path}/system/database.yml #{"#"}{release_path}/config/database.yml"
    run "ln -nfs #{"#"}{shared_path}/system/action_mailer_configs.rb #{"#"}{release_path}/config/initializers/action_mailer_configs.rb"
  end
  
  task :after_setup do
    put File.read('config/database.yml'), "#{"#"}{shared_path}/system/database.yml"
    put File.read('config/initializers/action_mailer_configs.rb'), "#{"#"}{shared_path}/system/action_mailer_configs.rb"
  end
  END
end

file 'app/helpers/application_helper.rb', 
%q{module ApplicationHelper
  def body_id
    "#{controller.controller_name}"
  end
end
}
 
file 'app/views/layouts/_flashes.html.erb', 
%q{<div id="flash">
  <% flash.each do |key, value| -%>
    <div id="flash_<%= key %>"><%=h value %></div>
  <% end -%>
</div>
}

file 'app/views/layouts/application.html.erb', <<LAYOUT
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-type" content="text/html; charset=utf-8">
  <title><%= "#{"#"}{@title} | " if @title %>#{PROJECT.humanize}</title>
  <meta name="description" content=""/>
  <link rel="shortcut icon" href="/favicon.ico"/>
  <%= stylesheet_link_tag "reset", :media => 'all', :cache => 'true' %>
  <%= stylesheet_link_tag "style", :media => 'all', :cache => 'true' %>
  
  <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.1/jquery.min.js" type="text/javascript" charset="utf-8"></script>
  <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.5.3/jquery-ui.min.js" type="text/javascript" charset="utf-8"></script> 
  <script type="text/javascript" charset="utf-8">
    jQuery.ajaxSetup({
      data: { authenticity_token: '<%= form_authenticity_token %>' }
    });
  </script>
</head>
<body id="<%= body_id %>">
  <div id="page">
    <%= render :partial => 'layouts/flashes' -%>
    <%= yield %>
  </div> <!-- #page -->
</body>
</html>
LAYOUT

initializer 'action_mailer_configs.rb', <<MAILER
  require 'smtp-tls'

  ActionMailer::Base.server_settings = {
    :address => "smtp.gmail.com",
    :port => "587",
    :domain => "#{PROJECT}.com",
    :authentication => :plain,
    :user_name => "USER",
    :password => "PASS"
  }
MAILER

run "cp config/database.yml config/database.yml.example"
run "cp config/initializers/action_mailer_configs.rb config/initializers/action_mailer_configs.rb.example"

git :init
git :add => '.'
git :commit => "-a -m 'Initial Commit'"

puts "-" * 79
puts "Edit config/initializers/action_mailer_configs.rb with your gmail user/pass"
puts "-" * 79