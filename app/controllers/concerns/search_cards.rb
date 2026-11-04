# How a partner search is sent to the card on a page.
module SearchCards
  extend ActiveSupport::Concern

  private

  def search_card(pair_request)
    pair_request.as_json(
      methods: [:commitment_label],
      include: {
        tags: { only: [:id, :name] },
        offers: { only: [:offerer_id] }
      }
    ).merge("user" => pair_request.user.profile_for_others.merge(id: pair_request.user_id, name: pair_request.user.name))
  end
end
