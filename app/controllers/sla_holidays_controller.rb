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

  # Bundesweite deutsche Feiertage eines Jahres eintragen (vorhandene werden übersprungen).
  def import
    year = params[:year].to_i
    year = Date.current.year unless year.between?(2000, 2100)
    created = 0
    RedmineSla::GermanHolidays.national(year).each do |date, name|
      next if RedmineSla::SlaHoliday.where(date: date, project_id: nil).exists?

      RedmineSla::SlaHoliday.create!(name: name, date: date, project_id: nil)
      created += 1
    end
    flash[:notice] = l(:notice_sla_holidays_imported, count: created, year: year)
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
