# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    # Statistiques API (24h)
    panel "Statistiques API (24h)" do
      stats = {
        total: ApiLog.today.count,
        success: ApiLog.today.success.count,
        errors: ApiLog.today.errors.count,
        avg_duration: ApiLog.today.average(:duration_ms)&.round(2)
      }
      
      div style: "display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; padding: 20px;" do
        div style: "text-align: center;" do
          div style: "font-size: 14px; color: #666; margin-bottom: 5px;" do
            "Total requêtes"
          end
          div style: "font-size: 32px; font-weight: bold; color: #333;" do
            stats[:total].to_s
          end
        end
        
        div style: "text-align: center;" do
          div style: "font-size: 14px; color: #666; margin-bottom: 5px;" do
            "Succès"
          end
          div style: "font-size: 32px; font-weight: bold; color: #28a745;" do
            stats[:success].to_s
          end
        end
        
        div style: "text-align: center;" do
          div style: "font-size: 14px; color: #666; margin-bottom: 5px;" do
            "Erreurs"
          end
          div style: "font-size: 32px; font-weight: bold; color: #{stats[:errors] > 0 ? '#dc3545' : '#28a745'};" do
            stats[:errors].to_s
          end
        end
        
        div style: "text-align: center;" do
          div style: "font-size: 14px; color: #666; margin-bottom: 5px;" do
            "Durée moy."
          end
          if stats[:avg_duration]
            avg = stats[:avg_duration].to_f
            color = case avg
                    when 0..100 then "#28a745"
                    when 101..500 then "#ffc107"
                    else "#dc3545"
                    end
            div style: "font-size: 32px; font-weight: bold; color: #{color};" do
              "#{avg.round(2)} ms"
            end
          else
            div style: "font-size: 32px; font-weight: bold; color: #999;" do
              "-"
            end
          end
        end
      end
    end
    
    # Ligne 1 : Endpoints + Dernières commandes
    div style: "display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-top: 20px;" do
      div do
        panel "Endpoints les plus appelés (7 jours)" do
          logs = ApiLog.this_week
                       .group(:endpoint)
                       .count
                       .sort_by { |_, count| -count }
                       .first(10)
          
          if logs.any?
            table_for logs, class: "index_table" do
              column("Endpoint") { |endpoint, _| code endpoint }
              column("Appels") { |_, count| strong count.to_s }
              column("") do |endpoint, _|
                link_to "Voir les logs", admin_api_logs_path(q: { endpoint_eq: endpoint })
              end
            end
          else
            para "Aucun appel cette semaine", style: "color: #999; text-align: center; padding: 20px;"
          end
        end
      end
      
      div do
        panel "Dernières commandes" do
          orders = Order.order(created_at: :desc).limit(5)
          if orders.any?
            table_for orders, class: "index_table" do
              column("Référence") { |order| link_to order.order_reference, admin_order_path(order) }
              column("Status") { |order| status_tag order.status }
              column("Date") { |order| "il y a #{time_ago_in_words(order.created_at)}" }
            end
          else
            para "Aucune commande", style: "color: #999; text-align: center; padding: 20px;"
          end
        end
      end
    end
    
    # Ligne 2 : Erreurs + Validations
    div style: "display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-top: 20px;" do
      div do
        panel "Dernières erreurs" do
          errors = ApiLog.errors.recent.limit(10)
          
          if errors.any?
            table_for errors, class: "index_table" do
              column("Date") { |log| "il y a #{time_ago_in_words(log.created_at)}" }
              column("Endpoint") do |log|
                link_to log.endpoint_name, admin_api_log_path(log)
              end
              column("Code") { |log| status_tag log.status_code, class: "error" }
              column("Partenaire") do |log|
                if log.partner
                  link_to log.partner.code, admin_partner_path(log.partner)
                else
                  "-"
                end
              end
            end
          else
            para "Aucune erreur récente 🎉", style: "color: #28a745; text-align: center; padding: 20px; font-weight: bold;"
          end
        end
      end
      
      div do
        panel "Validations (aujourd'hui)" do
          validations = ApiLog.today.validations
          total = validations.count
          success = validations.where(validation_success: true).count
          failed = validations.where(validation_success: false).count
          
          if total > 0
            div style: "padding: 20px; text-align: center;" do
              div style: "margin-bottom: 20px;" do
                span "Total: ", style: "font-size: 14px; color: #666;"
                strong total.to_s, style: "font-size: 24px;"
              end
              
              div style: "display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 20px;" do
                div do
                  status_tag "#{success} succès", class: "ok"
                end
                div do
                  status_tag "#{failed} échecs", class: "error"
                end
              end
              
              div do
                success_rate = (success.to_f / total * 100).round(1)
                color = success_rate > 90 ? "#28a745" : success_rate > 70 ? "#ffc107" : "#dc3545"
                span "Taux de succès: ", style: "color: #666;"
                strong "#{success_rate}%", style: "color: #{color}; font-size: 20px;"
              end
            end
          else
            para "Aucune validation aujourd'hui", style: "color: #999; text-align: center; padding: 20px;"
          end
        end
      end
    end
    
    # Ligne 3 : Top partenaires
    div style: "margin-top: 20px;" do
      panel "Top 5 partenaires (cette semaine)" do
        partner_stats = ApiLog.this_week
                              .joins(:partner)
                              .group("partners.code")
                              .count
                              .sort_by { |_, count| -count }
                              .first(5)
        
        if partner_stats.any?
          table_for partner_stats, class: "index_table" do
            column("Partenaire") { |code, _| link_to code, admin_partner_path(Partner.find_by(code: code)) }
            column("Requêtes") { |_, count| strong count.to_s }
          end
        else
          para "Aucune donnée", style: "color: #999; text-align: center; padding: 20px;"
        end
      end
    end
  end # content
end
