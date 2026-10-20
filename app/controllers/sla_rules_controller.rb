class SlaRulesController < ApplicationController
  layout 'admin'
  self.main_menu = false

  before_action :require_admin
  before_action :find_rule, only: [:edit, :update, :destroy]

  def index
    redirect_to sla_admin_path(tab: 'rules')
  end

  def new
    @sla_rule = RedmineSla::SlaRule.new(priority: 1)
  end

  def create
    @sla_rule = RedmineSla::SlaRule.new(sla_rule_params)
    if @sla_rule.save
      flash[:notice] = l(:notice_sla_rule_created)
      redirect_to sla_admin_path(tab: 'rules')
    else
      render :new
    end
  end

  def edit; end

  def update
    if @sla_rule.update(sla_rule_params)
      flash[:notice] = l(:notice_sla_rule_updated)
      redirect_to sla_admin_path(tab: 'rules')
    else
      render :edit
    end
  end

  def destroy
    @sla_rule.destroy
    flash[:notice] = l(:notice_sla_rule_deleted)
    redirect_to sla_admin_path(tab: 'rules')
  end

  private

  def find_rule
    @sla_rule = RedmineSla::SlaRule.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def sla_rule_params
    params.require(:sla_rule).permit(
      :name, :project_id, :tracker_id,
      :priority, :resolution_time_minutes, :initial_response_time_minutes, :response_time_minutes, :description
    )
  end
end
