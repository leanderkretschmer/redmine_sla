class RedmineSLA::SlaSetting < ActiveRecord::Base
  self.table_name = 'sla_settings'

  belongs_to :project, class_name: 'Project', optional: true
  has_many :sla_holidays

  def self.for_project(project)
    if project
      where(project_id: project.id).first ||
        where(project_id: nil).first
    else
      where(project_id: nil).first
    end
  end

  def self.get(key, default = nil)
    setting = where(key: key).first
    setting&.value || default
  end

  def self.set(key, value)
    setting = where(key: key).first_or_create(value: value)
  end
end
