# Kernlogik: legt Antwortfristen an, wenn Externe Tickets/Kommentare erzeugen,
# und erledigt sie, wenn Interne öffentlich antworten oder das Ticket schließen.
module RedmineSla
  module DeadlineTracker
    # Geschlossene Tickets werden beim Neuaufbau nur berücksichtigt, wenn sie kürzlich geändert wurden.
    RECENT_CLOSED_DAYS = 30

    class << self
      # Neuer Journal-Eintrag (Kommentar) gespeichert.
      def journal_created(journal)
        return unless journal.journalized_type == 'Issue' && journal.notes.present?

        issue = journal.journalized
        return unless issue

        setting = SlaSetting.for_project(issue.project)
        return unless setting

        if InternalUsers.internal?(journal.user)
          respond!(issue, journal) unless journal.private_notes?
        else
          open_deadline!(issue, setting, journal: journal, time: journal.created_on || Time.current)
        end
      rescue StandardError => e
        RedmineSla.log(:error, "journal_created(#{journal.id}): #{e.class}: #{e.message}")
      end

      # Neues Ticket angelegt.
      def issue_created(issue)
        setting = SlaSetting.for_project(issue.project)
        return unless setting
        return if InternalUsers.internal?(issue.author)

        open_deadline!(issue, setting, journal: nil, time: issue.created_on || Time.current)
      rescue StandardError => e
        RedmineSla.log(:error, "issue_created(#{issue.id}): #{e.class}: #{e.message}")
      end

      # Ticket wurde geschlossen: offene Fristen gelten als erledigt.
      def issue_closed(issue, by_user = User.current)
        SlaDeadline.pending.for_issue(issue).update_all(
          response_status: SlaDeadline::STATUS_CLOSED,
          responded_at: Time.current,
          responded_by_id: by_user&.id,
          updated_at: Time.current
        )
      rescue StandardError => e
        RedmineSla.log(:error, "issue_closed(#{issue.id}): #{e.class}: #{e.message}")
      end

      # Ticket in anderes Projekt verschoben.
      def issue_moved(issue)
        if SlaSetting.enabled_for?(issue.project)
          SlaDeadline.for_issue(issue).update_all(project_id: issue.project_id)
          rebuild_issue(issue, SlaSetting.for_project(issue.project))
        else
          SlaDeadline.pending.for_issue(issue).delete_all
        end
      rescue StandardError => e
        RedmineSla.log(:error, "issue_moved(#{issue.id}): #{e.class}: #{e.message}")
      end

      # Interne Antwort: alle offenen Fristen des Tickets erledigen.
      def respond!(issue, journal)
        SlaDeadline.pending.for_issue(issue).update_all(
          response_status: SlaDeadline::STATUS_RESPONDED,
          responded_at: journal.created_on || Time.current,
          responded_by_id: journal.user_id,
          response_journal_id: journal.id,
          updated_at: Time.current
        )
      end

      # Legt eine Frist an, falls für das Ticket noch keine offen ist. Der älteste
      # unbeantwortete externe Beitrag bestimmt die Frist.
      def open_deadline!(issue, setting, journal:, time:)
        return if SlaDeadline.pending.for_issue(issue).exists?

        response_minutes = setting.response_time_for(issue)
        times = setting.calendar.deadlines_for(time, response_minutes)
        rule = SlaRule.matching(issue.project, issue.tracker).first

        SlaDeadline.create!(
          issue_id: issue.id,
          project_id: issue.project_id,
          journal_id: journal&.id,
          sla_rule_id: rule&.id,
          external_comment_time: time,
          calculated_deadline: times[:calculated_deadline],
          internal_deadline: times[:internal_deadline],
          response_status: SlaDeadline::STATUS_PENDING
        )
      end

      # Baut die offenen Fristen eines Projekts aus der Ticket-Historie neu auf
      # (nach Aktivierung/Änderung der Projekt-SLA, Feiertagen oder Regeln).
      def rebuild_project(project)
        setting = SlaSetting.for_project(project)
        SlaDeadline.pending.for_project(project).delete_all
        return 0 unless setting

        count = 0
        issues = Issue.where(project_id: project.id)
                      .where('issues.status_id IN (?) OR issues.updated_on >= ?',
                             IssueStatus.where(is_closed: false).pluck(:id), RECENT_CLOSED_DAYS.days.ago)
                      .includes(:author, :tracker, :project)
        issues.find_each do |issue|
          count += 1 if rebuild_issue(issue, setting, purge: false)
        end
        count
      rescue StandardError => e
        RedmineSla.log(:error, "rebuild_project(#{project&.id}): #{e.class}: #{e.message}")
        0
      end

      def rebuild_all
        SlaSetting.includes(:project).find_each { |s| rebuild_project(s.project) if s.project }
      end

      # Ermittelt den ältesten externen Beitrag seit der letzten internen,
      # öffentlichen Antwort und legt dafür eine Frist an.
      def rebuild_issue(issue, setting, purge: true)
        SlaDeadline.pending.for_issue(issue).delete_all if purge
        return false unless setting

        closed_status_ids = IssueStatus.where(is_closed: true).pluck(:id).map(&:to_s)
        pending = nil
        pending = [issue.created_on, nil] unless InternalUsers.internal?(issue.author)

        issue.journals.includes(:user, :details).order(:created_on, :id).each do |j|
          closes = j.details.any? { |d| d.property == 'attr' && d.prop_key == 'status_id' && closed_status_ids.include?(d.value.to_s) }
          if InternalUsers.internal?(j.user)
            # Öffentliche Antwort oder Schließen durch Mitarbeiter erledigt die Antwortpflicht
            pending = nil if closes || (j.notes.present? && !j.private_notes?)
          elsif j.notes.present?
            pending ||= [j.created_on, j]
          end
        end
        return false unless pending

        open_deadline!(issue, setting, journal: pending[1], time: pending[0])
        true
      end
    end
  end
end
