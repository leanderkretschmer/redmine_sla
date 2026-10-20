require 'redmine'

# Hinweis: Redmine >= 5 lädt init.rb bereits innerhalb eines to_prepare-Blocks.
# Ein verschachteltes Rails.application.config.to_prepare würde in Produktion
# nie ausgeführt, daher werden die Patches hier direkt angewendet.
RedmineSla::Hooks # Hook-Listener laden (registriert sich beim Laden der Klasse)
Journal.include(RedmineSla::JournalPatch) unless Journal.include?(RedmineSla::JournalPatch)
Issue.include(RedmineSla::IssuePatch) unless Issue.include?(RedmineSla::IssuePatch)
MyController.prepend(RedmineSla::MyControllerPatch) unless MyController.include?(RedmineSla::MyControllerPatch)

Redmine::Plugin.register :redmine_sla do
  name 'Redmine SLA Plugin'
  author 'Leander Kretschmer'
  author_url 'https://github.com/leanderkretschmer'
  url 'https://github.com/leanderkretschmer/redmine_sla'
  description 'SLA-Management für Redmine - Reaktionsfristen für externe Tickets und Kommentare mit Ampelsystem.'
  version '0.4.0'

  requires_redmine version_or_higher: '6.0.0'

  settings default: {
    'default_response_time_minutes' => '240',
    'default_puffer_minutes' => '120',
    'default_sod_hour' => '7',
    'default_eod_hour' => '18',
    'time_zone' => 'Europe/Berlin',
    'admins_internal' => '1',
    'internal_group_id' => ''
  }, partial: 'settings/redmine_sla'

  # Eigene Seite unter Administration
  menu :admin_menu, :redmine_sla,
       { controller: 'sla_admin', action: 'index' },
       caption: :label_sla_admin,
       html: { class: 'icon icon-time' }

  # Projekt-Reiter "SLA" nur in Projekten mit SLA-Einstellungen
  permission :view_sla, { sla_projects: [:show], sla_dashboard: [:index] }, public: true, read: true

  menu :project_menu, :sla,
       { controller: 'sla_projects', action: 'show' },
       caption: :label_sla,
       param: :project_id,
       after: :activity,
       if: Proc.new { |project|
         project && User.current.allowed_to?(:view_issues, project) &&
           RedmineSla::SlaSetting.enabled_for?(project)
       }
end
