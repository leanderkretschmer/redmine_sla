# Projekt-Reiter "SLA": Einstellungen des Projekts und offene Antwortpflichten.
class SlaProjectsController < ApplicationController
  menu_item :sla

  before_action :find_project_by_project_id
  before_action :check_access

  def show
    @setting = RedmineSla::SlaSetting.for_project(@project)
    return render_404 unless @setting

    @board = RedmineSla::Board.for_user(User.current, project: @project)
    @holidays = RedmineSla::SlaHoliday.where(project_id: [nil, @project.id]).where('date >= ?', Date.current).sorted.limit(10).to_a
    @rules = RedmineSla::SlaRule.where(project_id: [nil, @project.id]).sorted_by_priority.includes(:tracker).to_a
  end

  private

  def check_access
    deny_access unless User.current.allowed_to?(:view_issues, @project)
  end
end
