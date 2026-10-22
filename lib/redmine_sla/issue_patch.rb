module RedmineSla
  module IssuePatch
    def self.included(base)
      base.class_eval do
        after_create_commit :redmine_sla_track_new_issue
        after_save :redmine_sla_track_changes
      end
    end

    private

    def redmine_sla_track_new_issue
      RedmineSla::DeadlineTracker.issue_created(self)
    end

    def redmine_sla_track_changes
      if saved_change_to_status_id?
        excluded = RedmineSla.excluded_status_ids
        now_excluded = excluded.include?(status_id)
        was_excluded = excluded.include?(status_id_before_last_save.to_i)
        RedmineSla::DeadlineTracker.issue_closed(self) if now_excluded && !was_excluded
      end
      RedmineSla::DeadlineTracker.issue_moved(self) if saved_change_to_project_id? && !saved_change_to_id?
    end
  end
end
