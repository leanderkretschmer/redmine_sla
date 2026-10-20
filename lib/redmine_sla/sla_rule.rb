class RedmineSla::SlaRule < ActiveRecord::Base
  self.table_name = 'sla_rules'

  belongs_to :project, class_name: 'Project', optional: true
  belongs_to :tracker, class_name: 'Tracker', optional: true

  has_many :sla_deadlines

  validates :name, presence: true
  validates :priority, numericality: { greater_than: 0 }
  validates :resolution_time_minutes, numericality: { greater_than: 0, allow_nil: true }
  validates :response_time_minutes, numericality: { greater_than: 0, allow_nil: true }

  attribute :working_hours, :json, default: -> {
    {
      sod_hour: RedmineSla::Setting.get(:sod_hour, 7),
      eod_hour: RedmineSla::Setting.get(:eod_hour, 18),
      puffer_minutes: RedmineSla::Setting.get(:puffer_minutes, 120)
    }
  }

  scope :for_project, ->(project) { where(project_id: project.id).or(where(project_id: nil)) }
  scope :for_tracker, ->(tracker_id) { where(tracker_id: tracker_id).or(where(tracker_id: nil)) }
  scope :sorted_by_priority, -> { order(priority: :desc) }

  def matches?(project:, tracker:)
    (project_id.nil? || project_id == project.id) &&
      (tracker_id.nil? || tracker_id == tracker.id)
  end

  def effective_working_hours(project)
    {
      sod_hour: 7,
      eod_hour: 18,
      puffer_minutes: 120
    }
  end

  def calculate_internal_deadline(comment_time, project)
    holidays = []
    SlaCalendar.calculate(
      comment_time,
      response_time_minutes,
      sod_hour: 7,
      eod_hour: 18,
      puffer_minutes: 120,
      exclude_weekends: true,
      holidays: holidays
    )
  end
end
