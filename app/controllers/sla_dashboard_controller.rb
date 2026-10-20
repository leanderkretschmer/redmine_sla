# Gesamtübersicht aller offenen Antwortpflichten (sichtbare Projekte des Nutzers).
class SlaDashboardController < ApplicationController
  before_action :require_login

  def index
    @board = RedmineSla::Board.for_user(User.current)
  end
end
