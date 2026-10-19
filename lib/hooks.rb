module RedmineSLA
  class Hooks < Redmine::Hook::Listener
    # Add CSS to project pages
    def view_layouts_base_head_tag(context = {})
      stylesheet_link_tag('sla_dashboard', plugin: :redmine_sla)
    end

    # Add SLA menu item
    def view_layouts_base_sidebar_menu(context = {})
      "<li>#{link_to(l(:sla_menu), { controller: 'sla_dashboard', action: 'index' }, class: 'icon icon-sla')}</li>"
    end

    # Register My Page widgets
    def controller_my_page_index_after(context = {})
      render_partial('sla_dashboard/my_page_widget', context)
    end
  end
end
