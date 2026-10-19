# encoding: utf-8
module SlaDashboardHelper
  # Determine if a user is part of the SLA team for a project
  def self.team_member?(user, project)
    # TODO: Implement team membership check
    # This should check against the project's team members
    # For now, assume the current user is always a team member
    true
  end

  # Check if a note is from an external (non-team) user
  def self.external_comment?(note, project)
    return false if note.nil?
    return false if note.is_private?
    user = User.find_by(id: note.<EMAIL>)
    return true unless user
    !team_member?(user, project)
  end
end
