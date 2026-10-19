class SlaDashboardController < ApplicationController
  self.plugin_name = 'redmine_sla'

  before_action :require_authentication

  layout 'plugin'

  def index
    # Get all projects the current user has access to
    @projects = Project.active.includes(:issues).to_a

    # Collect all pending SLA deadlines for visible projects
    @deadlines = SlaDeadline.pending.includes(:issue, :sla_rule, :issue_note).to_a
    @deadlines = @deadlines.select { |d| @projects.any? { |p| p.id == d.issue.project_id } }

    # Group deadlines by project
    @project_deadlines = {}
    @projects.each do |project|
      project_dl = @deadlines.select { |d| d.issue.project_id == project.id }
      next if project_dl.empty?

      # Sort: overdue, due today, upcoming - within each group sorted by deadline
      overdue = project_dl.select(&:overdue?)
      due_today = project_dl.select(&:due_today?)
      upcoming = project_dl.select(&:upcoming?)

      overdue.sort_by!(&:internal_deadline)
      due_today.sort_by!(&:internal_deadline)
      upcoming.sort_by!(&:internal_deadline)

      @project_deadlines[project] = overdue + due_today + upcoming
    end

    # Stats for dashboard header
    @stats = {
      breached: @deadlines.count(&:breached?),
      at_risk: @deadlines.count(&:at_risk?),
      ok: @deadlines.count(&:ok?)
    }
  end
end
