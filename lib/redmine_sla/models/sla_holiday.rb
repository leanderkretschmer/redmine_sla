class RedmineSLA::SlaHoliday < ActiveRecord::Base
  self.table_name = 'sla_holidays'

  belongs_to :project, class_name: 'Project', optional: true

  validates :date, presence: true
  validates :name, presence: true

  def self.is_holiday?(date, project = nil)
    conditions = { date: date }
    conditions[:project_id] = project.id if project
    where(conditions).exists?
  end
end
