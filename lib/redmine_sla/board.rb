# Baut die Spaltenansicht (ein Projekt = eine Spalte, Tickets als Ampelkarten).
module RedmineSla
  class Board
    attr_reader :deadlines, :columns, :stats

    def self.for_user(user = User.current, project: nil)
      scope = SlaDeadline.pending.visible(user).with_board_includes
      scope = scope.where(project_id: project.id) if project
      new(scope.to_a)
    end

    def initialize(deadlines)
      @deadlines = deadlines.select(&:issue).sort_by { |d| [d.sort_rank, d.internal_deadline] }
      grouped = @deadlines.group_by { |d| d.issue.project }
      @columns = grouped.sort_by { |project, _| project.name.to_s.downcase }
      @stats = {
        breached: @deadlines.count(&:breached?),
        at_risk: @deadlines.count(&:at_risk?),
        ok: @deadlines.count(&:ok?)
      }
    end

    def empty?
      @deadlines.empty?
    end

    def size
      @deadlines.size
    end
  end
end
