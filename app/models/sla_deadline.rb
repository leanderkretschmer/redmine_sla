class SlaDeadline < ActiveRecord::Base
  self.table_name = 'sla_deadlines'

  belongs_to :issue, class_name: 'Issue'
  belongs_to :sla_rule, class_name: 'SlaRule', optional: true
  belongs_to :issue_note, class_name: 'IssueNote', optional: true

  # Scopes for dashboard filtering
  scope :pending, -> { where(response_status: 'pending') }

  scope :overdue, -> { where(response_status: 'pending').where('internal_deadline < ?', Time.now) }
  scope :due_today, -> { where(response_status: 'pending')
                         .where('internal_deadline >= ? AND internal_deadline <= ?',
                                Date.today.beginning_of_day, Date.today.end_of_day) }
  scope :upcoming, -> { where(response_status: 'pending').where('internal_deadline > ?', Date.today.end_of_day) }

  scope :for_project, ->(project) { joins(:issue).where(issues: { project_id: project.id }) }
  scope :for_issues, ->(issue_ids) { where(issue_id: issue_ids) }

  # Instance methods for status checks
  def overdue?
    response_status == 'pending' && internal_deadline < Time.now
  end

  def due_today?
    return false unless response_status == 'pending'
    internal_deadline.to_date == Date.today
  end

  def upcoming?
    response_status == 'pending' && !overdue? && !due_today?
  end

  def breached?
    status == :breached
  end

  def at_risk?
    status == :at_risk
  end

  def ok?
    status == :ok
  end

  # Returns the traffic light status
  def status
    return :cleared if response_status != 'pending'
    return :breached if internal_deadline <= Time.now
    return :at_risk if internal_deadline.to_date == Date.today
    :ok
  end

  def status_label
    case status
    when :breached then 'breached'
    when :at_risk then 'at_risk'
    when :ok then 'ok'
    else 'pending'
    end
  end

  # Find the first unanswered external comment for this issue
  def first_unanswered_external_comment
    @first_unanswered_external_comment ||= begin
      external = issue.notes
                     .where(issuetracking_note: { is_private: false })
                     .where.not(issuetracking_note: { author_id: issue.project.team.pluck(:user_id) })
                     .order(created_at: :asc)
      # Skip any comments that have been followed by a team reply
      first_unanswered = nil
      team_reply_after = nil

      external.each do |note|
        team_reply = issue.notes
                         .where(issuetracking_note: { author_id: issue.project.team.pluck(:user_id) })
                         .where('created_at > ?', note.created_at)
                         .order(created_at: :asc).first
        if team_reply
          first_unanswered = external.take_while { |n| n.created_at < team_reply.created_at }.last
          break
        else
          first_unanswered = external.last
        end
      end

      first_unanswered
    end
  end
end
