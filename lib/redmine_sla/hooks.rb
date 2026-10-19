module RedmineSla
  class Hooks < Redmine::Hook::Listener
    def view_layouts_base_head_tag(context = {})
      stylesheet_link_tag('sla_dashboard', plugin: :redmine_sla)
    end
  end
end
