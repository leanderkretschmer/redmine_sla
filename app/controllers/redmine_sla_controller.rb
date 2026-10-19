class RedmineSlaController < ApplicationController
  self.plugin_name = 'redmine_sla'

  before_action :require_authentication
  before_action :find_project, only: [:index, :new, :create, :edit, :update]

  protect_from_forgery except: :api_check_sla

  layout 'plugin'

  def index
    @sla_rules = SlaRule.sorted_by_priority
    @sla_rules = @sla_rules.for_project(@project) if @project
  end

  def new
    @sla_rule = SlaRule.new
    assign_sla_form_defaults
  end

  def create
    @sla_rule = SlaRule.new(sla_rule_params)
    if @sla_rule.save
      redirect_to sla_rules_url, notice: l(:notice_sla_rule_created)
    else
      render :new
    end
  end

  def edit
    @sla_rule = SlaRule.find(params[:id])
  end

  def update
    @sla_rule = SlaRule.find(params[:id])
    if @sla_rule.update(sla_rule_params)
      redirect_to sla_rules_url, notice: l(:notice_sla_rule_updated)
    else
      render :edit
    end
  end

  def destroy
    @sla_rule = SlaRule.find(params[:id])
    @sla_rule.destroy
    redirect_to sla_rules_url, notice: l(:notice_sla_rule_deleted)
  end

  private

  def sla_rule_params
    params.require(:sla_rule).permit(
      :name, :project_id, :tracker_id, :status_id,
      :priority, :resolution_time_minutes, :response_time_minutes, :description
    )
  end

  def find_project
    @project = Project.find(params[:project_id]) if params[:project_id].present?
  end
end
