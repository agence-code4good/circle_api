require "test_helper"

class Api::V1::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @negoce   = partners(:nom_du_negoce)
    @circle   = partners(:circle)
  end

  test "POST /api/v1/orders as nom_du_negoce returns 422 and does not create order when alias is missing" do
    assert_difference("Order.count", 0) do
      post "/api/v1/orders",
        params: {
          order: {
            buyer_id: "nom_du_negoce",
            seller_id: "circle",
            order_reference: "ORG-2026-2032",
            initial_order_reference: nil,
            note: nil,
            status: "nouvelle_commande",
            previous_status: nil,
            accompanying_document_url: nil,
            latest_instruction_due_date: nil,
            estimated_availability_earliest_at: nil,
            order_lines_attributes: [
              {
                circle_code: {
                  "C10" => "5238A0",
                  "C11" => "2017",
                  "C13" => "A7",
                  "C31" => "1200",
                  "C0"  => "11",
                  "CLE" => "042"
                }
              }
            ]
          }
        },
        as: :json,
        headers: {
          "Authorization"  => "Bearer token-negoce",
          "X-Partner-Code" => "nom_du_negoce",
          "Accept"         => "application/json"
        }

      assert_response :unprocessable_entity

      body = JSON.parse(response.body)
      assert_equal [ "Alias introuvable pour nom_du_negoce" ], body.dig("errors", "buyer_id")

      # Vérifie que le debug alias est cohérent avec ce qu'on a vu en prod
      debug = assigns(:validation_errors)&.dig(:alias_lookup_debug)
      if debug
        assert_equal "nom_du_negoce", debug[:partner_code]
        assert_equal "nom_du_negoce", debug[:requested_buyer_id]
        assert_equal "circle",        debug[:requested_seller_id]
        assert_equal %w[circle nom_de_la_propriete].sort, debug[:available_external_ids].sort
      end
    end
  end

  test "PATCH /api/v1/orders/:id as circle succeeds on existing order" do
    order = orders(:org_2026_2032)

    patch "/api/v1/orders/#{order.order_reference}",
      params: {
        order: {
          buyer_id: "nom_du_negoce",
          seller_id: "circle",
          order_reference: "ORG-2026-2032",
          initial_order_reference: nil,
          note: nil,
          status: "nouvelle_commande",
          previous_status: nil,
          accompanying_document_url: nil,
          latest_instruction_due_date: nil,
          estimated_availability_earliest_at: nil,
          order_lines_attributes: [
            {
              circle_code: {
                "C0"  => "11",
                "C1"  => "00",
                "C2"  => "00",
                "C3"  => "00",
                "C4"  => "00",
                "C5"  => "00",
                "C6"  => "00",
                "C7"  => "00",
                "C8"  => "00",
                "C9"  => "00",
                "C10" => "5238A0",
                "C11" => "2017",
                "C12" => "00",
                "C13" => "A7",
                "C14" => "00",
                "C15" => "00",
                "C16" => "00",
                "C17" => "00",
                "C18" => "00",
                "C19" => "00",
                "C20" => "00",
                "C21" => "00",
                "C22" => "00",
                "C23" => "00",
                "C24" => "00",
                "C25" => "00",
                "C26" => "00",
                "C27" => "00",
                "C28" => "00",
                "C29" => "00",
                "C30" => "00",
                "C31" => "1200",
                "C34" => "00",
                "C35" => "00",
                "C36" => "00",
                "C38" => "00",
                "C40" => "00",
                "C41" => "00",
                "C42" => "00",
                "C43" => "00",
                "C44" => "00",
                "C45" => "00",
                "C46" => "00",
                "C47" => "00",
                "C48" => "00",
                "C49" => "00",
                "C50" => "00",
                "C51" => "00",
                "C59" => "00",
                "C60" => "00",
                "C61" => "00",
                "C62" => "00",
                "C66" => "00",
                "C68" => "00",
                "C69" => "00",
                "C70" => "00",
                "C71" => "00",
                "C72" => "00",
                "C73" => "00",
                "C74" => "00",
                "C75" => "00",
                "C76" => "00",
                "C78" => "00",
                "C79" => "00",
                "C80" => "00",
                "CLE" => "042"
              }
            }
          ]
        }
      },
      as: :json,
      headers: {
        "Authorization"  => "Bearer token-circle",
        "X-Partner-Code" => "circle",
        "Accept"         => "application/json"
      }

    assert_response :success

    body = JSON.parse(response.body)
    assert_equal "ORG-2026-2032", body.dig("order", "order_reference")
    assert_equal "nouvelle_commande", body.dig("order", "status")
    assert_equal "nom_du_negoce", body.dig("order", "buyer_id")
    assert_equal "circle",         body.dig("order", "seller_id")
  end
end
