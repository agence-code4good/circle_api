class ApiLog < ApplicationRecord
  belongs_to :partner, optional: true
  belongs_to :order, optional: true

  # Scopes pour filtres et dashboard
  scope :recent, -> { order("api_logs.created_at DESC") }
  scope :errors, -> { where("api_logs.status_code >= ?", 400) }
  scope :success, -> { where("api_logs.status_code < ?", 400) }
  scope :validations, -> { where("api_logs.endpoint LIKE ?", "%validation%") }
  scope :orders_api, -> { where("api_logs.endpoint LIKE ?", "%orders%") }
  scope :products_api, -> { where("api_logs.endpoint LIKE ?", "%products%") }
  scope :circle_values_api, -> { where("api_logs.endpoint LIKE ?", "%circle_values%") }
  scope :today, -> { where("api_logs.created_at >= ?", Time.zone.now.beginning_of_day) }
  scope :yesterday, -> { where("api_logs.created_at" => 1.day.ago.beginning_of_day..1.day.ago.end_of_day) }
  scope :this_week, -> { where("api_logs.created_at >= ?", 1.week.ago) }
  scope :this_month, -> { where("api_logs.created_at >= ?", 1.month.ago) }

  # ActiveAdmin Ransackable attributes
  def self.ransackable_associations(auth_object = nil)
    [ "order", "partner" ]
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "duration_ms", "endpoint", "error_backtrace", "error_message", "http_method", "id", "id_value", "ip_address", "order_id", "partner_id", "path", "request_body", "request_headers", "request_id", "request_params", "response_body", "status_code", "updated_at", "user_agent", "validation_errors", "validation_success" ]
  end


  # Helpers
  def success?
    status_code && status_code.to_i < 400
  end

  def error?
    !success?
  end

  def client_error?
    status_code && status_code.to_i >= 400 && status_code.to_i < 500
  end

  def server_error?
    status_code && status_code.to_i >= 500
  end

  def duration_seconds
    duration_ms ? (duration_ms.to_i / 1000.0).round(2) : nil
  end

  def endpoint_name
    endpoint&.split("/")&.last || "unknown"
  end

  def http_method_color
    case http_method&.to_s
    when "GET" then "yes"
    when "POST" then "warning"
    when "PATCH", "PUT" then "warning"
    when "DELETE" then "error"
    else "default"
    end
  end

  def status_color
    return "default" unless status_code

    code = status_code.to_i
    case code
    when 200..299 then "ok"
    when 400..499 then "warning"
    when 500..599 then "error"
    else "default"
    end
  end
end
