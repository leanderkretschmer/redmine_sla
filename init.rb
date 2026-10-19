Redmine::Plugin.register :redmine_sla do
  name 'Redmine SLA Plugin'
  author 'Leander Kretschmer'
  author_url 'https://github.com/leanderkretschmer'
  description 'This is a plugin for managing SLA (Service Level Agreements) in Redmine.'
  version '0.2.0'
  url 'https://github.com/leanderkretschmer/redmine_sla'
end

# Load all library files
require 'redmine_sla'
require 'redmine_sla/engine'
require 'sla_calendar'
require 'my_page_widget'

# Register My Page widget
Redmine::AppHook.register :redmine_sla do
  require 'redmine/survey'
end
