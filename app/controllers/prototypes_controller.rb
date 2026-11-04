# PROTOTYPE ONLY: throwaway chat-first UI. The route exists only in development
# and test, and it signs in the first confirmed user so one URL just works.
class PrototypesController < ApplicationController
  layout "application"

  before_action { sign_in(User.where.not(confirmed_at: nil).first!) unless user_signed_in? }

  def chat_first
    render inertia: "Prototype/ChatFirst", props: {}
  end
end
