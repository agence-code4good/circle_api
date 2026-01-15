ActiveAdmin.register ApiLog do
  menu priority: 2, label: "Logs API"
  
  # Configuration
  config.per_page = 50
  config.sort_order = "created_at_desc"
  
  # Filtres
  filter :partner
  filter :order
  filter :endpoint, as: :select, collection: -> { ApiLog.distinct.pluck(:endpoint).compact.sort }
  filter :http_method, as: :select, collection: %w[GET POST PATCH PUT DELETE]
  filter :status_code
  filter :validation_success, as: :select, collection: [["Succès", true], ["Échec", false]]
  filter :created_at
  filter :request_id
  filter :ip_address
  
  # Scope tabs
  scope :all, default: true
  scope("Aujourd'hui") { |scope| scope.today }
  scope("Hier") { |scope| scope.yesterday }
  scope("Cette semaine") { |scope| scope.this_week }
  scope("Ce mois") { |scope| scope.this_month }
  scope("Erreurs", &:errors)
  scope("Succès", &:success)
  scope("Validations", &:validations)
  scope("Commandes", &:orders_api)
  scope("Produits", &:products_api)
  
  # Index
  index do
    selectable_column
    
    column "Date", :created_at, sortable: :created_at do |log|
      div do
        div l(log.created_at, format: :short)
        small style: "color: #999;" do
          "il y a #{time_ago_in_words(log.created_at)}"
        end
      end
    end
    
    column "Endpoint", sortable: :endpoint do |log|
      status_tag log.endpoint_name, class: log.success? ? "ok" : "error"
    end
    
    column "Méthode", :http_method, sortable: :http_method do |log|
      status_tag log.http_method, class: log.http_method_color
    end
    
    column "Partenaire", :partner, sortable: "partners.code" do |log|
      if log.partner
        link_to log.partner.code, admin_partner_path(log.partner)
      else
        span "-", style: "color: #999;"
      end
    end
    
    column "Commande", :order do |log|
      if log.order
        link_to log.order.order_reference, admin_order_path(log.order)
      else
        span "-", style: "color: #999;"
      end
    end
    
    column "Status", :status_code, sortable: :status_code do |log|
      status_tag log.status_code, class: log.status_color
    end
    
    column "Durée", :duration_ms, sortable: :duration_ms do |log|
      if log.duration_ms
        duration = log.duration_ms.to_i
        color = case duration
                when 0..100 then "green"
                when 101..500 then "orange"
                else "red"
                end
        span style: "color: #{color}; font-weight: bold;" do
          "#{duration} ms"
        end
      else
        "-"
      end
    end
    
    column "Validation" do |log|
      if log.validation_success.nil?
        "-"
      elsif log.validation_success
        status_tag "✓", class: "ok"
      else
        status_tag "✗", class: "error"
      end
    end
    
    actions
  end
  
  # Show
  show do
    attributes_table do
      row :id
      row :created_at do |log|
        "#{l(log.created_at, format: :long)} (il y a #{time_ago_in_words(log.created_at)})"
      end
      row :request_id
    end
    
    panel "Partenaire & Commande" do
      attributes_table_for api_log do
        row :partner do |log|
          if log.partner
            link_to log.partner.code, admin_partner_path(log.partner)
          else
            span "-", style: "color: #999;"
          end
        end
        row :order do |log|
          if log.order
            div do
              div link_to(log.order.order_reference, admin_order_path(log.order))
              small style: "color: #666;" do
                "Status: #{log.order.status}"
              end
            end
          else
            span "-", style: "color: #999;"
          end
        end
      end
    end
    
    panel "Requête" do
      attributes_table_for api_log do
        row :http_method do |log|
          status_tag log.http_method, class: log.http_method_color
        end
        row :endpoint
        row :path
        row :ip_address
        row :user_agent do |log|
          if log.user_agent.present?
            text_node log.user_agent.to_s.truncate(100)
          else
            span "-", style: "color: #999;"
          end
        end
        row "Headers" do |log|
          pre style: "background: #f4f4f4; padding: 10px; border-radius: 4px; overflow-x: auto;" do
            JSON.pretty_generate(log.request_headers || {})
          end
        end
        row "Query Params" do |log|
          if log.request_params.present?
            pre style: "background: #f4f4f4; padding: 10px; border-radius: 4px; overflow-x: auto;" do
              JSON.pretty_generate(log.request_params)
            end
          else
            span "-", style: "color: #999;"
          end
        end
        row "Body" do |log|
          if log.request_body.present?
            pre style: "background: #f4f4f4; padding: 10px; border-radius: 4px; overflow-x: auto; max-height: 400px;" do
              begin
                JSON.pretty_generate(JSON.parse(log.request_body))
              rescue JSON::ParserError
                log.request_body
              end
            end
          else
            span "-", style: "color: #999;"
          end
        end
      end
    end
    
    panel "Réponse" do
      attributes_table_for api_log do
        row :status_code do |log|
          status_tag log.status_code, class: log.status_color
        end
        row :duration_ms do |log|
          if log.duration_ms
            duration = log.duration_ms.to_i
            color = case duration
                    when 0..100 then "green"
                    when 101..500 then "orange"
                    else "red"
                    end
            span style: "color: #{color}; font-weight: bold; font-size: 16px;" do
              "#{duration} ms (#{log.duration_seconds} s)"
            end
          else
            "-"
          end
        end
        row "Body" do |log|
          if log.response_body.present?
            pre style: "background: #f4f4f4; padding: 10px; border-radius: 4px; overflow-x: auto; max-height: 400px;" do
              JSON.pretty_generate(log.response_body)
            end
          else
            span "-", style: "color: #999;"
          end
        end
      end
    end
    
    if api_log.error_message.present?
      panel "Erreur", class: "error" do
        attributes_table_for api_log do
          row :error_message do |log|
            div style: "background: #ffebee; padding: 10px; border-left: 4px solid #f44336; border-radius: 4px;" do
              strong style: "color: #c62828;" do
                log.error_message
              end
            end
          end
          row :error_backtrace do |log|
            if log.error_backtrace.present?
              pre style: "background: #f4f4f4; padding: 10px; border-radius: 4px; overflow-x: auto; font-size: 11px; max-height: 300px;" do
                log.error_backtrace
              end
            end
          end
        end
      end
    end
    
    if api_log.validation_errors.present?
      panel "Erreurs de validation" do
        attributes_table_for api_log do
          row :validation_success do |log|
            status_tag(log.validation_success ? "Succès" : "Échec", class: log.validation_success ? "ok" : "error")
          end
          row :validation_errors do |log|
            pre style: "background: #fff3e0; padding: 10px; border-radius: 4px; overflow-x: auto;" do
              JSON.pretty_generate(log.validation_errors)
            end
          end
        end
      end
    end
  end
  
  # Pas de création/modification manuelle
  config.clear_action_items!
  actions :index, :show
end
