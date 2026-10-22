# Popup-Ansicht einer Antwortpflicht (Ticket/Kommentar) und Herausnahme aus der SLA-Betrachtung.
class SlaDeadlinesController < ApplicationController
  before_action :require_login
  before_action :find_deadline
  before_action :authorize_exclude, only: [:exclude]

  helper :issues
  helper :journals
  helper :attachments

  def show
    @issue = @deadline.issue
    @journals = @issue.visible_journals_with_index(User.current)
    @can_exclude = can_exclude?
    render partial: 'sla_deadlines/show', layout: false
  end

  def exclude
    RedmineSla::DeadlineTracker.exclude!(@deadline, User.current)
    if request.xhr?
      render json: { ok: true, issue_id: @deadline.issue_id, pending: RedmineSla::SlaDeadline.pending.for_issue(@deadline.issue).count }
    else
      flash[:notice] = l(:notice_sla_excluded)
      redirect_back_or_default sla_dashboard_path
    end
  end

  private

  def find_deadline
    @deadline = RedmineSla::SlaDeadline.includes(:issue, :journal).find(params[:id])
    render_404 unless @deadline.issue&.visible?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def can_exclude?
    User.current.admin? || RedmineSla::InternalUsers.internal?(User.current)
  end

  def authorize_exclude
    deny_access unless can_exclude?
  end
end
