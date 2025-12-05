class Api::V1::OrdersController < Api::BaseController
  before_action :authenticate_partner!
  rescue_from ArgumentError, with: :handle_enum_argument_error

  def create
    order = Order.new(order_params)

    policy = OrderPolicy.new(@current_partner, order)
    unless policy.create?
      render json: { error: "Forbidden : You must be the buyer to create an order" }, status: :forbidden
      return
    end

    status_string = order.status.to_s
    unless status_string == "nouvelle_commande"
      render json: { error: "Invalid status for new order. Must be 'nouvelle_commande'" }, status: :unprocessable_entity
      return
    end

    if order.save
      @order = order
      render json: { order: @order }, status: :created
    else
      render json: { errors: format_errors(order) }, status: :unprocessable_entity
    end
  end

  def update
    @order = Order.find_by(order_reference: params[:id])
    unless @order
      render json: { error: "Order not found" }, status: :not_found
      return
    end

    policy = OrderPolicy.new(@current_partner, @order)
    unless policy.update?
      render json: { error: "Forbidden" }, status: :forbidden
      return
    end

    new_status = order_params[:status]
    if new_status && new_status != @order.status.to_s
      unless policy.allowed_status?(new_status)
        render json: { error: "Forbidden : Status '#{new_status}' is not allowed for your role" }, status: :forbidden
        return
      end
    end

    order_lines_in_params = params.dig(:order, :order_lines_attributes)
    
    if order_lines_in_params
      # Stocker les volumes originaux AVANT toute modification
      @order.prepare_order_lines_replacement
      
      # Sauvegarder les order_lines originales pour restauration en cas d'erreur
      original_order_lines_ids = @order.order_lines.pluck(:id)
      
      # Créer temporairement les nouvelles order_lines pour validation (sans toucher aux anciennes)
      new_order_lines_data = order_params[:order_lines_attributes] || []
      temp_order_lines = new_order_lines_data.map do |attrs|
        OrderLine.new(order: @order, circle_code: attrs[:circle_code])
      end
      
      # Valider les nouvelles order_lines individuellement
      temp_order_lines.each(&:valid?)
      temp_order_lines.each do |line|
        line.errors.each do |error|
          @order.errors.add(:order_lines, "#{error.attribute}: #{error.message}")
        end
      end
      
      # Remplacer temporairement l'association pour la validation de l'order
      # (sans toucher à la base de données)
      original_order_lines = @order.order_lines.to_a
      @order.association(:order_lines).target = temp_order_lines
      
      # Assigner les autres attributs
      update_params = order_params.except(:order_lines_attributes)
      @order.assign_attributes(update_params)
      
      # Valider l'order avec les nouvelles order_lines temporaires
      unless @order.valid?
        # Restaurer l'association originale en cas d'erreur
        @order.association(:order_lines).target = original_order_lines
        @order.association(:order_lines).reset
        render json: { errors: format_errors(@order) }, status: :unprocessable_entity
        return
      end
      
      # Si validation réussit, remplacer dans une transaction
      Order.transaction do
        # Supprimer les anciennes order_lines
        OrderLine.where(id: original_order_lines_ids).destroy_all
        
        # Réinitialiser l'association pour éviter les conflits
        @order.association(:order_lines).reset
        
        # Créer les nouvelles order_lines
        new_order_lines_data.each do |attrs|
          @order.order_lines.create!(circle_code: attrs[:circle_code])
        end
        
        # Sauvegarder les autres attributs de l'order
        @order.save!
      end
      
      render json: { order: @order.reload }, status: :ok
    else
      # Pas de modification des order_lines, mise à jour normale
      update_params = order_params.except(:order_lines_attributes)
      
      if @order.update(update_params)
        render json: { order: @order }, status: :ok
      else
        render json: { errors: format_errors(@order) }, status: :unprocessable_entity
      end
    end
  end

  private

  def format_errors(order)
    errors = {}

    order.errors.each do |error|
      next if error.attribute.to_s.start_with?("order_lines")

      if error.attribute == :base
        errors[:base] ||= []
        errors[:base] << error.message
      else
        errors[error.attribute] ||= []
        errors[error.attribute] << error.message
      end
    end

    order.order_lines.each_with_index do |order_line, index|
      next if order_line.errors.empty?

      order_line.errors.each do |error|
        errors[:"order_lines[#{index}]"] ||= []
        errors[:"order_lines[#{index}]"] << error.message
      end
    end

    errors
  end

  def handle_enum_argument_error(exception)
    if exception.message.match?(/is not a valid/)
      render json: { errors: [ "#{exception.message}" ] }, status: :unprocessable_entity
    else
      raise exception
    end
  end

  def order_params
    params.require(:order).permit(
      :order_reference,
      :initial_order_reference,
      :buyer_id,
      :seller_id,
      :note,
      :status,
      order_lines_attributes: [
        { circle_code: {} }
      ]
    )
  end
end
