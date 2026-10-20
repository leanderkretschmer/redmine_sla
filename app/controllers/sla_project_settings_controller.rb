class SlaProjectSettingsController < ApplicationController
  layout 'admin'
  self.main_menu = false

  before_action :require_admin
  before_action :find_setting, only: [:edit, :update, :destroy]

  def new
    @setting = RedmineSla::SlaSetting.new_with_defaults(project_id: params[:project_id])
  end

  def create
    @setting = RedmineSla::SlaSetting.new_with_defaults
    @setting.safe_attributes = setting_params
    @setting.project_id = setting_params[:project_id]
    if @setting.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to sla_admin_path(tab: 'projects')
    else
      render :new
    end
  end

  def edit; end

  def update
    @setting.safe_attributes = setting_params
    if @setting.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to sla_admin_path(tab: 'projects')
    else
      render :edit
    end
  end

  def destroy
    @setting.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to sla_admin_path(tab: 'projects')
  end

  private

  def find_setting
    @setting = RedmineSla::SlaSetting.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def setting_params
    params.require(:sla_setting).permit(
      :project_id, :response_time_minutes, :puffer_minutes_before_eod,
      :sod_hour, :eod_hour, :exclude_weekends, :exclude_holidays
    )
  end
end
