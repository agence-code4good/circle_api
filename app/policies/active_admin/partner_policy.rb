# frozen_string_literal: true

class ActiveAdmin::PartnerPolicy < ApplicationPolicy
  class Scope < Scope
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

  def new?
    create?
  end

  def create?
    user.admin?
  end

  def edit?
    update?
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

  def record_outbound_challenge?
    user.admin?
  end

  def approve_key?
    user.admin?
  end
end
