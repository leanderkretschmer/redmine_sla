module RedmineSla
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(_context = {})
      stylesheet_link_tag('sla_dashboard', plugin: :redmine_sla)
    end
  end
end
