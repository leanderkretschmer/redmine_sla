class SlaRule < ActiveRecord::Base
  self.table_name = 'sla_rules'

  belongs_to :project, class_name: 'Project', optional: true
  belongs_to :tracker, class_name: 'Tracker', optional: true
  belongs_to :status, class_name: 'IssueStatus', optional: true

  has_many :sla_deadlines

  validates :name, presence: true
  validates :priority, numericality: { greater_than: 0 }
  validates :resolution_time_minutes, numericality: { greater_than: 0, allow_nil: true }
  validates :response_time_minutes, numericality: { greater_than: 0, allow_nil: true }

  # Working hours settings (stored as JSON)
  # { sod_hour: 7, eod_hour: 18, puffer_minutes: 120 }
  attribute :working_hours, :json, default: -> { { sod_hour: 7, eod_hour: 18, puffer_minutes: 120 } }

  scope :for_project, ->(project) { where(project_id: project.id).or(where(project_id: nil)) }
  scope :for_tracker, ->(tracker_id) { where(tracker_id: tracker_id).or(where(tracker_id: nil)) }
  scope :for_status, ->(status_id) { where(status_id: status_id).or(where(status_id: nil)) }
  scope :sorted_by_priority, -> { order(priority: :desc) }

  def matches?(project:, tracker:, status:)
    (project_id.nil? || project_id == project.id) &&
      (tracker_id.nil? || tracker_id == tracker.id) &&
      (status_id.nil? || status_id == status.id)
  end

  # Get effective working hours for a project
  def effective_working_hours(project)
    setting = SlaSetting.for_project(project)
    if setting
      {
        sod_hour: setting.sod_hour,
        eod_hour: setting.eod_hour,
        puffer_minutes: setting.puffer_minutes_before_eod
      }
    else
      working_hours.to_h
    end
  end

  # Calculate the internal deadline for a given comment time
  def calculate_internal_deadline(comment_time, project)
    wh = effective_working_hours(project)
    holidays = SlaHoliday.where(project_id: [project.id, nil]).pluck(:date)

    SlaCalendar.calculate(
      comment_time,
      response_time_minutes,
      sod_hour: wh[:sod_hour],
      eod_hour: wh[:eod_hour],
      puffer_minutes: wh[:puffer_minutes],
      exclude_weekends: true,
      holidays: holidays
    )
  end
end
