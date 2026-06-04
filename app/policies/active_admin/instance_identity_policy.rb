# frozen_string_literal: true

class ActiveAdmin::InstanceIdentityPolicy < ApplicationPolicy
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

  def rotate_identity?
    user.admin?
  end
end
