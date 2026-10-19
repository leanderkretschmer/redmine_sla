class SlaDashboardController < ApplicationController
  before_action :require_authentication

  layout 'base'

  def index
    @projects = Project.active.to_a

    @deadlines = RedmineSla::SlaDeadline.pending.includes(:issue, :sla_rule, :issue_note).to_a
    @deadlines = @deadlines.select { |d| @projects.any? { |p| p.id == d.issue.project_id } }

    @project_deadlines = {}
    @projects.each do |project|
      project_dl = @deadlines.select { |d| d.issue.project_id == project.id }
      next if project_dl.empty?

      overdue = project_dl.select(&:overdue?)
      due_today = project_dl.select(&:due_today?)
      upcoming = project_dl.select(&:upcoming?)

      overdue.sort_by!(&:internal_deadline)
      due_today.sort_by!(&:internal_deadline)
      upcoming.sort_by!(&:internal_deadline)

      @project_deadlines[project] = overdue + due_today + upcoming
    end

    @stats = {
      breached: @deadlines.count(&:breached?),
      at_risk: @deadlines.count(&:at_risk?),
      ok: @deadlines.count(&:ok?)
    }
  end
end
