class SlaRule < ActiveRecord::Base
  self.table_name = 'sla_rules'

  belongs_to :project, class_name: 'Project', optional: true
  belongs_to :tracker, class_name: 'Tracker', optional: true
  belongs_to :status, class_name: 'IssueStatus', optional: true

  validates :name, presence: true
  validates :priority, numericality: { greater_than: 0 }
  validates :resolution_time_minutes, numericality: { greater_than: 0, allow_nil: true }
  validates :response_time_minutes, numericality: { greater_than: 0, allow_nil: true }

  scope :for_project, ->(project) { where(project_id: project.id).or(where(project_id: nil)) }
  scope :for_tracker, ->(tracker_id) { where(tracker_id: tracker_id).or(where(tracker_id: nil)) }
  scope :for_status, ->(status_id) { where(status_id: status_id).or(where(status_id: nil)) }
  scope :sorted_by_priority, -> { order(priority: :desc) }

  def matches?(project:, tracker:, status:)
    (project_id.nil? || project_id == project.id) &&
      (tracker_id.nil? || tracker_id == tracker.id) &&
      (status_id.nil? || status_id == status.id)
  end

  def resolved?
    resolution_time_minutes.present? && response_time_minutes.present?
  end
end
