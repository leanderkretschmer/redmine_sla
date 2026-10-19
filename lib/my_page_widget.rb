# SLA Widget for Redmine My Page
# Registers a widget on the "My Page" dashboard

module RedmineSLA
  class MyPageWidget < Redmine::MenuMapper
    def call(menu)
      menu.my_page :sla_overview,
                   { controller: 'sla_dashboard', action: 'index' },
                   url: { controller: 'sla_dashboard', action: 'index' },
                   caption: 'sla_dashboard',
                   html: true
    end
  end
end
