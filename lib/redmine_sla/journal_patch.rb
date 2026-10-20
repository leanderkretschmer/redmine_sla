module RedmineSla
  module JournalPatch
    def self.included(base)
      base.class_eval do
        after_create_commit :redmine_sla_track_journal
      end
    end

    private

    def redmine_sla_track_journal
      RedmineSla::DeadlineTracker.journal_created(self)
    end
  end
end
