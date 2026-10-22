# Ein Auslöser (Ticketerstellung oder externer Kommentar), der bewusst keine
# Antwortfrist erzeugen soll. journal_id = nil steht für die Ticketerstellung.
class RedmineSla::SlaExclusion < ActiveRecord::Base
  self.table_name = 'sla_exclusions'

  belongs_to :issue, class_name: 'Issue'
  belongs_to :journal, class_name: 'Journal', optional: true
  belongs_to :user, class_name: 'User', optional: true

  validates :issue_id, presence: true
  validates :journal_id, uniqueness: { scope: :issue_id }

  scope :sorted, -> { order(created_at: :desc) }

  def self.excluded?(issue_id, journal_id)
    where(issue_id: issue_id, journal_id: journal_id).exists?
  end

  def self.excluded_journal_ids(issue_id)
    where(issue_id: issue_id).where.not(journal_id: nil).pluck(:journal_id)
  end

  def self.ticket_excluded?(issue_id)
    where(issue_id: issue_id, journal_id: nil).exists?
  end

  def for_ticket?
    journal_id.nil?
  end
end
