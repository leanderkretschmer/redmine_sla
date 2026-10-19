require 'redmine'

require_relative 'lib/redmine_sla'

Redmine::Plugin.register :redmine_sla do
  name 'Redmine SLA Plugin'
  author 'Leander Kretschmer'
  author_url 'https://github.com/leanderkretschmer'
  description 'SLA-Management für Redmine - Tracking von Reaktionsfristen mit Ampelsystem.'
  version '0.3.0'
  settings default: {
    'default_response_time_minutes' => '240',
    'default_puffer_minutes' => '120',
    'default_sod_hour' => '7',
    'default_eod_hour' => '18'
  }, partial: 'settings/redmine_sla'
end
