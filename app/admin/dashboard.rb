# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    div class: "grid grid-cols-2 gap-4" do
      div do
        panel "Bienvenue" do
          para "Bienvenue sur le tableau de bord de Circle."
        end
      end
      div do
        panel "Dernières commandes" do
          ul do
            Order.order(created_at: :desc).limit(5).map do |order|
              li link_to(order.order_reference, admin_order_path(order))
            end
          end
        end
      end
    end
  end # content
end
