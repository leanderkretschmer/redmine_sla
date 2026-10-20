# Feiertage (global oder projektspezifisch), die bei der Fristberechnung ausgelassen werden.
class RedmineSla::SlaHoliday < ActiveRecord::Base
  self.table_name = 'sla_holidays'

  belongs_to :project, class_name: 'Project', optional: true

  validates :date, presence: true
  validates :name, presence: true, length: { maximum: 255 }
  validates :date, uniqueness: { scope: :project_id }

  scope :sorted, -> { order(date: :asc) }
  scope :global, -> { where(project_id: nil) }

  after_commit :rebuild_deadlines

  def self.dates_for(project)
    scope = project ? where(project_id: [nil, project.id]) : global
    scope.pluck(:date)
  end

  def self.is_holiday?(date, project = nil)
    dates_for(project).include?(date.to_date)
  end

  private

  def rebuild_deadlines
    if project
      RedmineSla::DeadlineTracker.rebuild_project(project)
    else
      RedmineSla::DeadlineTracker.rebuild_all
    end
  end
end
