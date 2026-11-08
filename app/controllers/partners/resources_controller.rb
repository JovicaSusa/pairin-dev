# A Workspace's Resources page: links either partner can add or remove. Once the
# partnership has ended they stay readable, but nobody can change them.
class Partners::ResourcesController < ApplicationController
  include Authenticated
  include WorkspacePages

  before_action :set_partnership
  before_action :refuse_if_ended, only: [:create, :destroy]

  def index
    links = @partnership.shared_links.order(created_at: :desc, id: :desc)

    render inertia: "Partners/Resources", props: {
      partnership: workspace(@partnership).merge(
        resources: links.map { |link|
          { id: link.id, url: link.url, host: link.host, note: link.note, mine: link.added_by_id == current_user.id }
        }
      )
    }
  end

  def create
    link = @partnership.shared_links.new(added_by: current_user, url: params[:url].to_s, note: params[:note].to_s)

    if link.save
      ConversationsChannel.notify(@partnership.offer)
      redirect_to partner_resources_path(@partnership)
    else
      redirect_to partner_resources_path(@partnership), inertia: { errors: link.errors.to_hash(true).transform_values(&:first) }
    end
  end

  def destroy
    @partnership.shared_links.find(params[:id]).destroy!
    ConversationsChannel.notify(@partnership.offer)

    redirect_to partner_resources_path(@partnership)
  end

  private

  def set_partnership
    @partnership = partnerships.find(params[:partner_id])
  end

  def refuse_if_ended
    redirect_to partner_resources_path(@partnership), alert: "This partnership has ended." if @partnership.ended?
  end
end
