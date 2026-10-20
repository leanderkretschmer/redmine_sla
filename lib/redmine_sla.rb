# Namespace des SLA-Plugins. Die Klassen unter lib/redmine_sla/ werden von
# Zeitwerk (Redmine >= 5) automatisch geladen; hier liegen nur kleine Helfer.
module RedmineSla
  def self.settings
    Setting.plugin_redmine_sla || {}
  rescue StandardError
    {}
  end

  def self.setting(key, default = nil)
    value = settings[key.to_s]
    value.nil? || value.to_s.strip.empty? ? default : value
  end

  # Zeitzone, in der Geschäftszeiten (SOD/EOD) interpretiert werden.
  def self.time_zone
    ActiveSupport::TimeZone[setting(:time_zone, 'Europe/Berlin').to_s] ||
      Time.zone ||
      ActiveSupport::TimeZone['UTC']
  end

  def self.log(level, message)
    Rails.logger.public_send(level, "[redmine_sla] #{message}") if Rails.logger
  end
end
