# Gesamtübersicht aller offenen Antwortpflichten (sichtbare Projekte des Nutzers).
# Mit ?embed=1&key=<Feed-Schlüssel> auch ohne Redmine-Rahmen und ohne Session einbettbar.
class SlaDashboardController < ApplicationController
  skip_before_action :check_if_login_required, only: [:index]
  before_action :sla_authenticate

  def index
    @project = Project.find_by(identifier: params[:project_id]) || Project.find_by(id: params[:project_id]) if params[:project_id].present?
    @board = RedmineSla::Board.for_user(User.current, project: @project, mine: params[:mine].present?)

    if @embed
      @refresh = params[:refresh].to_i
      @refresh = 30 if @refresh.positive? && @refresh < 30
      response.headers.delete('X-Frame-Options')
      render :embed, layout: false
    end
  end

  private

  # Einbettung: Feed-Schlüssel des Nutzers (nur lesend, wie bei Atom-Feeds) statt Session.
  def sla_authenticate
    @embed = params[:embed].present?
    if @embed && params[:key].present?
      user = RedmineSla.user_by_feed_key(params[:key].to_s)
      if user&.active?
        User.current = user
        return
      end
    end
    require_login
  end
end
