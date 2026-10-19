module RedmineSLA
  module IssueExtensions
    extend ActiveSupport::Concern

    included do
      has_one :sla_calculation, class_name: 'SlaCalculation', foreign_key: :issue_id, dependent: :destroy

      after_save :recalculate_sla, if: -> { status_id_changed? || is_private_changed? }
    end

    def sla_status
      sla_rule = find_matching_sla_rule
      return :no_sla if sla_rule.nil?

      calculation = SlaCalculation.new(self, sla_rule).calculate
      return :no_sla if calculation.nil?

      if sla_rule.resolution_time_minutes.present?
        hours_left = sla_rule.resolution_time_minutes - (calculation.time_to_resolution || 0)
        if hours_left <= 0
          :breached
        elsif hours_left <= sla_rule.resolution_time_minutes * 0.25
          :at_risk
        else
          :ok
        end
      else
        :ok
      end
    end

    def sla_rules_for_context
      SlaRule.for_project(self.project)
             .for_tracker(self.tracker_id)
             .sorted_by_priority
    end

    private

    def find_matching_sla_rule
      sla_rules_for_context.first
    end

    def recalculate_sla
      return unless persisted?
      # SLA recalculation will be handled by background job or cron
    end
  end
end
