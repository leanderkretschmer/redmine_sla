class SlaExclusionsController < ApplicationController
  before_action :require_admin

  def destroy
    exclusion = RedmineSla::SlaExclusion.find(params[:id])
    RedmineSla::DeadlineTracker.unexclude!(exclusion)
    flash[:notice] = l(:notice_successful_delete)
    redirect_to sla_admin_path(tab: 'exclusions')
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
