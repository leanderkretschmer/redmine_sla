class RedmineSLA::SlaRulesController < ApplicationController
  before_action :require_authentication

  def index
    @sla_rules = RedmineSLA::SlaRule.sorted_by_priority
  end

  def new
    @sla_rule = RedmineSLA::SlaRule.new
  end

  def create
    @sla_rule = RedmineSLA::SlaRule.new(sla_rule_params)
    if @sla_rule.save
      redirect_to sla_rules_path, notice: l(:notice_sla_rule_created)
    else
      render :new
    end
  end

  def edit
    @sla_rule = RedmineSLA::SlaRule.find(params[:id])
  end

  def update
    @sla_rule = RedmineSLA::SlaRule.find(params[:id])
    if @sla_rule.update(sla_rule_params)
      redirect_to sla_rules_path, notice: l(:notice_sla_rule_updated)
    else
      render :edit
    end
  end

  def destroy
    @sla_rule = RedmineSLA::SlaRule.find(params[:id])
    @sla_rule.destroy
    redirect_to sla_rules_path, notice: l(:notice_sla_rule_deleted)
  end

  private

  def sla_rule_params
    params.require(:sla_rule).permit(
      :name, :project_id, :tracker_id,
      :priority, :resolution_time_minutes, :response_time_minutes, :description
    )
  end
end
