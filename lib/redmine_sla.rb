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

  # Ticket-Status, bei denen keine Antwortpflicht (mehr) besteht.
  # Ohne Konfiguration: alle als "geschlossen" markierten Status.
  def self.excluded_status_ids
    ids = Array(settings['excluded_status_ids']).map(&:to_i).select(&:positive?)
    ids = IssueStatus.where(is_closed: true).pluck(:id) if ids.empty?
    ids
  end

  def self.status_excluded?(issue)
    return false unless issue

    excluded_status_ids.include?(issue.status_id)
  end

  # Persönlicher, nur lesender Feed-Schlüssel (Redmine 6: atom_key, davor rss_key).
  def self.feed_key_for(user)
    user.respond_to?(:atom_key) ? user.atom_key : user.rss_key
  end

  def self.user_by_feed_key(key)
    return nil if key.blank?

    if User.respond_to?(:find_by_atom_key)
      User.find_by_atom_key(key)
    else
      User.find_by_rss_key(key)
    end
  end

  def self.log(level, message)
    Rails.logger.public_send(level, "[redmine_sla] #{message}") if Rails.logger
  end
end
