require 'test_helper'

class SlaRuleTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_create_rule
    rule = SlaRule.new(
      name: 'Test SLA',
      priority: 1,
      resolution_time_minutes: 60,
      response_time_minutes: 30
    )
    assert rule.save
  end
end
