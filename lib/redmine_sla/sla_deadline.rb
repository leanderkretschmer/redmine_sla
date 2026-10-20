# Eine offene (oder erledigte) Antwortpflicht: ein externer Kommentar bzw. ein
# extern erstelltes Ticket, das von einem internen Mitarbeiter beantwortet werden muss.
class RedmineSla::SlaDeadline < ActiveRecord::Base
  self.table_name = 'sla_deadlines'

  STATUS_PENDING   = 'pending'.freeze
  STATUS_RESPONDED = 'responded'.freeze
  STATUS_CLOSED    = 'closed'.freeze

  belongs_to :issue, class_name: 'Issue'
  belongs_to :project, class_name: 'Project', optional: true
  belongs_to :journal, class_name: 'Journal', optional: true
  belongs_to :sla_rule, class_name: 'RedmineSla::SlaRule', optional: true
  belongs_to :responded_by, class_name: 'User', optional: true
  belongs_to :response_journal, class_name: 'Journal', optional: true

  scope :pending, -> { where(response_status: STATUS_PENDING) }
  scope :for_project, ->(project) { where(project_id: project.id) }
  scope :for_issue, ->(issue) { where(issue_id: issue.id) }
  scope :visible, ->(user = User.current) {
    joins(issue: :project).where(Issue.visible_condition(user))
  }
  scope :with_board_includes, -> {
    includes(:journal, :sla_rule, issue: [:project, :author, :assigned_to, :status, :tracker])
  }

  def pending?
    response_status == STATUS_PENDING
  end

  # Wer hat die Antwortpflicht ausgelöst (Kommentarautor oder Ticketersteller)?
  def external_author
    journal ? journal.user : issue&.author
  end

  def from_comment?
    journal_id.present?
  end

  def status
    return :cleared unless pending?

    now = Time.current
    return :breached if internal_deadline <= now
    return :at_risk if internal_deadline.in_time_zone(RedmineSla.time_zone).to_date <= now.in_time_zone(RedmineSla.time_zone).to_date

    :ok
  end

  def breached?; status == :breached; end
  def at_risk?;  status == :at_risk;  end
  def ok?;       status == :ok;       end

  # Ampelfarbe für Views
  def traffic_light
    case status
    when :breached then 'red'
    when :at_risk  then 'yellow'
    when :ok       then 'green'
    else 'grey'
    end
  end

  def status_label
    status == :cleared ? 'pending' : status.to_s
  end

  def sort_rank
    { breached: 0, at_risk: 1, ok: 2 }.fetch(status, 3)
  end

  def remaining_minutes
    ((internal_deadline - Time.current) / 60).round
  end
end
