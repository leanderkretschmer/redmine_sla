class SlaCalculation
  attr_reader :issue, :sla_rule, :resolved, :time_to_resolution, :time_to_response

  def initialize(issue, sla_rule)
    @issue = issue
    @sla_rule = sla_rule
    @resolved = false
    @time_to_resolution = nil
    @time_to_response = nil
  end

  def calculate
    return nil if sla_rule.nil?

    calculate_response_time
    calculate_resolution_time

    self
  end

  private

  def calculate_response_time
    return unless sla_rule.response_time_minutes.present?

    response_created = @issue.notes.where.not(<EMAIL> => nil).order(:created_at).first
    return unless response_created

    @time_to_response = ((response_created.created_at - @issue.created_at) / 60.0).round(2)
  end

  def calculate_resolution_time
    return unless sla_rule.resolution_time_minutes.present?
    return if @issue.status.closed?

    @time_to_resolution = ((Time.now - @issue.created_at) / 60.0).round(2)
    @resolved = true
  end

  def resolved?
    @issue.status.closed?
  end
end
