class SlaHolidaysController < ApplicationController
  before_action :require_admin

  def create
    @holiday = RedmineSla::SlaHoliday.new(holiday_params)
    if @holiday.save
      flash[:notice] = l(:notice_successful_create)
    else
      flash[:error] = @holiday.errors.full_messages.join(', ')
    end
    redirect_to sla_admin_path(tab: 'holidays')
  end

  def destroy
    RedmineSla::SlaHoliday.find(params[:id]).destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to sla_admin_path(tab: 'holidays')
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def holiday_params
    params.require(:sla_holiday).permit(:name, :date, :project_id)
  end
end
