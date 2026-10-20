# SLA-Konfiguration eines Projekts. Existiert kein Datensatz, hat das Projekt
# kein SLA: keine Fristen, kein Projekt-Reiter.
class RedmineSla::SlaSetting < ActiveRecord::Base
  self.table_name = 'sla_settings'

  include Redmine::SafeAttributes

  belongs_to :project, class_name: 'Project'

  safe_attributes 'response_time_minutes', 'puffer_minutes_before_eod',
                  'sod_hour', 'eod_hour', 'exclude_weekends', 'exclude_holidays'

  validates :project_id, presence: true, uniqueness: true
  validates :response_time_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :puffer_minutes_before_eod, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sod_hour, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
  validates :eod_hour, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 24 }
  validate :eod_after_sod

  after_commit :rebuild_deadlines, on: [:create, :update]
  after_commit :purge_deadlines, on: :destroy

  scope :sorted, -> { joins(:project).order('projects.name ASC') }

  def self.for_project(project)
    return nil unless project

    find_by(project_id: project.id)
  end

  def self.enabled_for?(project)
    return false unless project

    where(project_id: project.id).exists?
  end

  # Vorbelegung neuer Projekt-SLAs aus den globalen Plugin-Einstellungen.
  def self.defaults
    {
      response_time_minutes: RedmineSla.setting(:default_response_time_minutes, 240).to_i,
      puffer_minutes_before_eod: RedmineSla.setting(:default_puffer_minutes, 120).to_i,
      sod_hour: RedmineSla.setting(:default_sod_hour, 7).to_i,
      eod_hour: RedmineSla.setting(:default_eod_hour, 18).to_i,
      exclude_weekends: true,
      exclude_holidays: true
    }
  end

  def self.new_with_defaults(attrs = {})
    new(defaults.merge(attrs))
  end

  def calendar
    RedmineSla::SlaCalendar.new(
      sod_hour: sod_hour,
      eod_hour: eod_hour,
      puffer_minutes: puffer_minutes_before_eod,
      exclude_weekends: exclude_weekends,
      holidays: exclude_holidays ? RedmineSla::SlaHoliday.dates_for(project) : []
    )
  end

  # Reaktionsfrist in Minuten für ein Ticket: SLA-Regel (Projekt/Tracker) vor Projektstandard.
  def response_time_for(issue)
    RedmineSla::SlaRule.response_time_for(project, issue.tracker) || response_time_minutes
  end

  def response_time_hours
    (response_time_minutes.to_f / 60).round(1)
  end

  private

  def eod_after_sod
    return if sod_hour.nil? || eod_hour.nil?

    errors.add(:eod_hour, :greater_than, count: sod_hour) if eod_hour <= sod_hour
  end

  def rebuild_deadlines
    RedmineSla::DeadlineTracker.rebuild_project(project) if project
  end

  def purge_deadlines
    RedmineSla::SlaDeadline.pending.where(project_id: project_id).delete_all
  end
end
