# frozen_string_literal: true

class ActiveAdmin::PartnerConnectionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def index?
    user.admin?
  end

  def show?
    user.admin?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def fetch_identity?
    user.admin?
  end

  def outbound_challenge?
    user.admin?
  end

  def approve_key?
    user.admin?
  end
end
