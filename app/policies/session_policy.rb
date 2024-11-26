class SessionPolicy < ApplicationPolicy
  def update?
    user == record.sessionable.user
  end
end
