class Api::V1::OrdersController < Api::BaseController
  before_action :authenticate_partner!

  def create
    # Vérifier que l'utilisateur authentifié est le buyer
    order = Order.new(order_params)

    # Vérifier que l'utilisateur authentifié est le buyer
    policy = OrderPolicy.new(@current_partner, order)
    unless policy.actor_role == :buyer
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
      render json: order, status: :created
    else
      render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @order = Order.find(params[:id])
    policy = OrderPolicy.new(@current_partner, @order)

    # Vérifier que l'utilisateur a le droit de modifier cette commande
    unless policy.update?
      render json: { error: "Forbidden" }, status: :forbidden
      return
    end

    # Vérifier que la transition de statut est autorisée
    new_status = order_params[:status]
    if new_status && new_status != @order.status.to_s
      unless @order.allowed_transition?(new_status)
        render json: { error: "Invalid status transition from '#{@order.status}' to '#{new_status}'" }, status: :unprocessable_entity
        return
      end

      # Vérifier que le statut est autorisé pour le rôle de l'utilisateur
      unless policy.allowed_status?(new_status)
        render json: { error: "Status '#{new_status}' is not allowed for your role" }, status: :forbidden
        return
      end
    end

    # Vérifier que la order line est valide et que le volume total de la commande n'a pas été modifié (dans les validations du model OrderLine & Order)
    if @order.update(order_params)
      render json: @order, status: :ok
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
  end

  def index
  end

  private

  def authenticate_partner!
    token = request.headers["Authorization"].to_s.remove("Bearer ")
    @current_partner = Partner.find_by(auth_token: token)
    head :unauthorized unless @current_partner
  end


  def order_params
    params.require(:order).permit(
      :order_reference,
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
