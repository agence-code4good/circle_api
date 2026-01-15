class ActiveAdmin::ApiLogPolicy < ApplicationPolicy
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

  def new?
    false # Pas de création manuelle de logs
  end

  def create?
    false # Pas de création manuelle de logs
  end

  def edit?
    false # Pas de modification de logs
  end

  def update?
    false # Pas de modification de logs
  end

  def destroy?
    false # Pas de suppression de logs
  end
end
