# Administration > SLA: Projekt-SLAs, Feiertage und Sonderregeln.
class SlaAdminController < ApplicationController
  layout 'admin'
  self.main_menu = false

  before_action :require_admin

  def index
    @settings = RedmineSla::SlaSetting.sorted.includes(:project).to_a
    @holidays = RedmineSla::SlaHoliday.sorted.includes(:project).to_a
    @rules = RedmineSla::SlaRule.sorted_by_priority.includes(:project, :tracker).to_a
    @holiday = RedmineSla::SlaHoliday.new(date: Date.current)
    @projects_without_sla = Project.active.where.not(id: @settings.map(&:project_id)).sorted.to_a
    @import_year = Date.current.year

    # Ampelzähler je Projekt und gesamt
    zone = RedmineSla.time_zone
    now = Time.current
    today = now.in_time_zone(zone).to_date
    @lights = Hash.new { |h, k| h[k] = { red: 0, yellow: 0, green: 0 } }
    RedmineSla::SlaDeadline.pending.pluck(:project_id, :internal_deadline).each do |project_id, deadline|
      key = if deadline <= now then :red
            elsif deadline.in_time_zone(zone).to_date <= today then :yellow
            else :green
            end
      @lights[project_id][key] += 1
    end
    @totals = { red: 0, yellow: 0, green: 0 }
    @lights.each_value { |l| l.each { |k, v| @totals[k] += v } }
  end
end
