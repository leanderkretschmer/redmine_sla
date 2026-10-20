# Optionale Sonderregel: abweichende Fristen für Projekt und/oder Tracker
# (Reaktionszeit neues Ticket und/oder Antwortzeit auf Kommentare).
# Ohne passende Regel gelten die Fristen aus den Projekt-SLA-Einstellungen.
class RedmineSla::SlaRule < ActiveRecord::Base
  self.table_name = 'sla_rules'

  belongs_to :project, class_name: 'Project', optional: true
  belongs_to :tracker, class_name: 'Tracker', optional: true
  has_many :sla_deadlines, class_name: 'RedmineSla::SlaDeadline', dependent: :nullify

  validates :name, presence: true, length: { maximum: 255 }
  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :initial_response_time_minutes, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validates :response_time_minutes, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validate :at_least_one_time
  validates :resolution_time_minutes, numericality: { only_integer: true, greater_than: 0, allow_nil: true }

  scope :sorted_by_priority, -> { order(priority: :desc, id: :asc) }

  after_commit :rebuild_deadlines

  def self.response_time_for(project, tracker, kind = :comment)
    return nil unless project

    column = kind.to_sym == :initial ? :initial_response_time_minutes : :response_time_minutes
    matching(project, tracker).where.not(column => nil).first&.public_send(column)
  end

  def self.matching(project, tracker)
    where(project_id: [nil, project.id])
      .where(tracker_id: [nil, tracker&.id].compact)
      .sorted_by_priority
  end

  def matches?(project:, tracker:)
    (project_id.nil? || project_id == project&.id) &&
      (tracker_id.nil? || tracker_id == tracker&.id)
  end

  private

  def at_least_one_time
    if initial_response_time_minutes.blank? && response_time_minutes.blank?
      errors.add(:response_time_minutes, :blank)
    end
  end

  def rebuild_deadlines
    if project
      RedmineSla::DeadlineTracker.rebuild_project(project)
    else
      RedmineSla::DeadlineTracker.rebuild_all
    end
  end
end
