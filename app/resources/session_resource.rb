class SessionResource < ApplicationResource
  attributes :id

  attribute :subject do |session|
    session.sessionable.subject
  end

  attribute :start_at do |session|
    session.start_at.to_fs(:short)
  end

  attribute :end_at do |session|
    session.end_at.to_fs(:short)
  end

  attribute :call_link do |session|
    format_url(session.call_link)
  end

  attribute :is_holder do |session|
    session.hold_by_user?(params[:current_user])
  end

  attribute :holder_name do |session|
    session.holder.name
  end

  attribute :other_participant do |session|
    other = session.other_participant(params[:current_user])
    
    if other
      {
        name: other.name,
        image_url: other.image_url,
        profession: other.profession,
        level: other.level&.titlecase
      }
    end
  end
end
