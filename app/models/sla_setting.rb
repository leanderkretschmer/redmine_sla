class SlaSetting < ActiveRecord::Base
  self.table_name = 'sla_settings'

  belongs_to :project, class_name: 'Project', optional: true
  has_many :sla_deadlines
  has_many :sla_holidays

  # Find settings for a project, fall back to global (nil project)
  def self.for_project(project)
    if project
      where(project_id: project.id).first ||
        where(project_id: nil).first
    else
      where(project_id: nil).first
    end
  end
end
