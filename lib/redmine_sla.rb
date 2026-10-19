module RedmineSla
end

require_relative 'redmine_sla/models/sla_rule'
require_relative 'redmine_sla/models/sla_deadline'
require_relative 'redmine_sla/models/sla_setting'
require_relative 'redmine_sla/models/sla_holiday'
require_relative 'redmine_sla/calendar/sla_calendar'
require_relative 'redmine_sla/hooks'

ActiveSupport::Reloader.to_prepare do
end

module RedmineSla
  class Setup
    def self.ensure_settings
    end
  end
end

Rails.application.config.after_initialize do
  RedmineSla::Setup.ensure_settings
end
