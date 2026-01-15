module ApiLoggable
  extend ActiveSupport::Concern
  
  included do
    around_action :log_api_request
  end
  
  private
  
  def log_api_request
    start_time = Time.current
    
    # Lire le body une seule fois
    request_body = request.body.read
    request.body.rewind
    
    begin
      # Exécuter la requête
      yield
      
      # Logger le succès
      duration = ((Time.current - start_time) * 1000).to_i
      log_request_success(request_body, duration)
      
    rescue StandardError => e
      # Logger l'erreur
      duration = ((Time.current - start_time) * 1000).to_i
      log_request_error(request_body, duration, e)
      raise e
    end
  end
  
  def log_request_success(request_body, duration)
    ApiLog.create(
      request_id: request.request_id,
      partner: @current_partner,
      http_method: request.method,
      endpoint: request.path,
      path: request.fullpath,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      request_headers: extract_relevant_headers,
      request_params: request.query_parameters,
      request_body: sanitize_body(request_body),
      status_code: response.status,
      response_body: parse_response_body,
      duration_ms: duration,
      order: @order,
      validation_success: @validation_success,
      validation_errors: @validation_errors
    )
  rescue StandardError => e
    Rails.logger.error "Failed to log API request: #{e.message}"
  end
  
  def log_request_error(request_body, duration, error)
    ApiLog.create(
      request_id: request.request_id,
      partner: @current_partner,
      http_method: request.method,
      endpoint: request.path,
      path: request.fullpath,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      request_headers: extract_relevant_headers,
      request_params: request.query_parameters,
      request_body: sanitize_body(request_body),
      status_code: 500,
      error_message: error.message,
      error_backtrace: error.backtrace&.first(10)&.join("\n"),
      duration_ms: duration,
      order: @order
    )
  rescue StandardError => e
    Rails.logger.error "Failed to log API error: #{e.message}"
  end
  
  def extract_relevant_headers
    {
      authorization: request.headers["Authorization"].present? ? "Bearer [REDACTED]" : nil,
      content_type: request.headers["Content-Type"],
      accept: request.headers["Accept"],
      user_agent: request.headers["User-Agent"]
    }.compact
  end
  
  def parse_response_body
    body = response.body
    return nil if body.blank?
    
    # Limiter la taille pour éviter de stocker trop de données
    if body.length > 100_000
      return { message: "[RESPONSE TOO LARGE]", size: body.length }
    end
    
    JSON.parse(body)
  rescue JSON::ParserError
    body
  rescue StandardError
    nil
  end
  
  def sanitize_body(body)
    return nil if body.blank?
    
    # Limiter la taille
    return "[REQUEST TOO LARGE]" if body.length > 100_000
    
    body
  end
end
