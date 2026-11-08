# What every Workspace page needs: the viewer's own partnerships, and the props
# its shared header shows.
module WorkspacePages
  extend ActiveSupport::Concern

  private

  def workspace(partnership)
    offer = partnership.offer

    {
      id: partnership.id,
      goal: partnership.goal,
      ended: partnership.ended?,
      ended_by_viewer: partnership.ended_by_id == current_user.id,
      conversation: {
        id: offer.id,
        other: offer.other_person(current_user).profile_for_others.slice(:name, :image_url),
        search: { subject: offer.pair_request.subject }
      }
    }
  end

  def partnerships
    Partnership.involving(current_user)
  end
end
