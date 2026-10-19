class RedmineSLA::SlaDeadline < ActiveRecord::Base
  self.table_name = 'sla_deadlines'

  belongs_to :issue, class_name: 'Issue'
  belongs_to :sla_rule, class_name: 'RedmineSLA::SlaRule', optional: true
  belongs_to :issue_note, class_name: 'IssueNote', optional: true

  scope :pending, -> { where(response_status: 'pending') }

  scope :overdue, -> { where(response_status: 'pending').where('internal_deadline < ?', Time.now) }
  scope :due_today, -> { where(response_status: 'pending')
                         .where('internal_deadline >= ? AND internal_deadline <= ?',
                                Date.today.beginning_of_day, Date.today.end_of_day) }
  scope :upcoming, -> { where(response_status: 'pending').where('internal_deadline > ?', Date.today.end_of_day) }

  scope :for_project, ->(project) { joins(:issue).where(issues: { project_id: project.id }) }
  scope :for_issues, ->(issue_ids) { where(issue_id: issue_ids) }

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
end
