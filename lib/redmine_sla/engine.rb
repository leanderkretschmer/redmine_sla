module RedmineSLA
  class Engine < Rails::Engine
    isolate_namespace RedmineSLA

    config.autoload_once_paths = %W(
      #{root}/lib
      #{root}/app/helpers
      #{root}/app/models/concerns
    )

    config.to_prepare do
      Issue.send :include, RedmineSLA::IssueExtensions
    end
  end
end
