Redmine::Plugin.register :redmine_sla do
  name 'Redmine SLA Plugin'
  author 'Leander Kretschmer'
  author_url 'https://github.com/leanderkretschmer'
  description 'This is a plugin for managing SLA (Service Level Agreements) in Redmine.'
  version '0.1.0'
  url 'https://github.com/leanderkretschmer/redmine_sla'
end

require 'redmine_sla'
