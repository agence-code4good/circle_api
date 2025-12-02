class Api::V1::OrdersController < Api::BaseController
  before_action :authenticate_partner!
  rescue_from ArgumentError, with: :handle_enum_argument_error

  def create
    # Vérifier que l'utilisateur authentifié est le buyer
    order = Order.new(order_params)

    # Vérifier que l'utilisateur authentifié est le buyer
    policy = OrderPolicy.new(@current_partner, order)
    unless policy.create?
      render json: { error: "Forbidden : You must be the buyer to create an order" }, status: :forbidden
      return
    end

    # Vérifier la validité du status (pour une nouvelle commande, on vérifie que le status est "nouvelle_commande")
    status_string = order.status.to_s
    unless status_string == "nouvelle_commande"
      render json: { error: "Invalid status for new order. Must be 'nouvelle_commande'" }, status: :unprocessable_entity
      return
    end

    # Vérifier que la order line est valide (dans les validations du model OrderLine)
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

    # Vérifier que l'utilisateur a le droit de modifier cette commande
    unless policy.update?
      render json: { error: "Forbidden" }, status: :forbidden
      return
    end

    # Vérifier que la transition de statut est autorisée pour l'utilisateur authentifié
    new_status = order_params[:status]
    if new_status && new_status != @order.status.to_s
      # Vérifier que le statut est autorisé pour le rôle de l'utilisateur
      unless policy.allowed_status?(new_status)
        render json: { error: "Forbidden : Status '#{new_status}' is not allowed for your role" }, status: :forbidden
        return
      end
    end

    # Vérifier que la order line est valide et que le volume total de la commande n'a pas été modifié (dans les validations du model OrderLine & Order)
    if @order.update(order_params)
      render json: { order: @order }, status: :ok
    else
      render json: { errors: format_errors(@order) }, status: :unprocessable_entity
    end
  end

  private

  def format_errors(order)
    errors = {}

    # Erreurs de l'order (en excluant celles liées à l'association order_lines)
    order.errors.each do |error|
      # Ignorer les erreurs sur l'association order_lines
      next if error.attribute.to_s.start_with?("order_lines")

      if error.attribute == :base
        errors[:base] ||= []
        errors[:base] << error.message
      else
        errors[error.attribute] ||= []
        errors[error.attribute] << error.message
      end
    end

    # Erreurs des order_lines (récupérées directement depuis chaque order_line)
    order.order_lines.each_with_index do |order_line, index|
      next if order_line.errors.empty?

      order_line.errors.each do |error|
        errors[:"order_lines[#{index}]"] ||= []
        message = error.message
        errors[:"order_lines[#{index}]"] << message
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
        :id,
        :_destroy,
        { circle_code: {} }
      ]
  )
  end
end
