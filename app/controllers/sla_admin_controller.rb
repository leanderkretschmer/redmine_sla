# Administration > SLA: Projekt-SLAs, Feiertage und Sonderregeln.
class SlaAdminController < ApplicationController
  layout 'admin'
  self.main_menu = false

  before_action :require_admin

  def index
    @settings = RedmineSla::SlaSetting.sorted.includes(:project).to_a
    @holidays = RedmineSla::SlaHoliday.sorted.includes(:project).to_a
    @rules = RedmineSla::SlaRule.sorted_by_priority.includes(:project, :tracker).to_a
    @holiday = RedmineSla::SlaHoliday.new
    @pending_counts = RedmineSla::SlaDeadline.pending.group(:project_id).count
    @breached_counts = RedmineSla::SlaDeadline.pending.where('internal_deadline <= ?', Time.current).group(:project_id).count
    @projects_without_sla = Project.active.where.not(id: @settings.map(&:project_id)).sorted.to_a
  end
end
