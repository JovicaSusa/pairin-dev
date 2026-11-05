# A Workspace: the page two partners share. Only those two can open it.
class PartnershipsController < ApplicationController
  include Authenticated

  def index
    partnerships = Partnership.involving(current_user)
      .includes(:pair_request, offer: :offerer, pair_request: :user)
      .order(Arel.sql("partnerships.ended_at IS NOT NULL"), created_at: :desc)

    render inertia: "Partners/Index", props: {
      partnerships: partnerships.map { |partnership|
        partner = partnership.offer.other_person(current_user).profile_for_others

        {
          id: partnership.id,
          goal: partnership.goal,
          subject: partnership.pair_request.subject,
          ended: partnership.ended?,
          partner: partner.slice(:name, :image_url)
        }
      }
    }
  end

  def show
    partnership = partnerships.includes(:check_ins).find(params[:id])
    partnership.offer.mark_read_by!(current_user)
    partner = partnership.offer.other_person(current_user)

    render inertia: "Partners/Show", props: {
      partnership: {
        id: partnership.id,
        goal: partnership.goal,
        ended: partnership.ended?,
        ended_by_viewer: partnership.ended_by_id == current_user.id,
        weeks: partnership.weeks_summary,
        next_check_in_at: partnership.next_check_in_at.utc.iso8601,
        your_commitment: partnership.commitment_of(current_user),
        partner_commitment: partnership.commitment_of(partner),
        conversation: ConversationPresenter.new(partnership.offer, current_user).thread
      }
    }
  end

  def update
    partnership = partnerships.find(params[:id])

    if partnership.ended?
      redirect_to partner_path(partnership), alert: "This partnership has ended."
    elsif partnership.update(goal: params.fetch(:goal, partnership.goal).to_s)
      ConversationsChannel.notify(partnership.offer)
      redirect_to partner_path(partnership)
    else
      redirect_to partner_path(partnership), inertia: { errors: partnership.errors.to_hash(true) }
    end
  end

  def end_partnership
    partnership = partnerships.find(params[:id])

    if partnership.end!(by: current_user, reason: params[:reason].to_s.strip.first(Message::MAX_LENGTH))
      ConversationsChannel.notify(partnership.offer)
    end

    redirect_to partner_path(partnership)
  end

  private

  def partnerships
    Partnership.involving(current_user)
  end
end
