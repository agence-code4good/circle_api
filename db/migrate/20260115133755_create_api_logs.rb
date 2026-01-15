class CreateApiLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :api_logs do |t|
      # Identification
      t.string :request_id, null: false
      
      # Partenaire
      t.references :partner, foreign_key: true
      
      # Requête
      t.string :http_method, null: false
      t.string :endpoint, null: false
      t.string :path
      t.inet :ip_address
      t.string :user_agent
      t.jsonb :request_headers, default: {}
      t.jsonb :request_params, default: {}
      t.text :request_body
      
      # Réponse
      t.integer :status_code
      t.jsonb :response_body
      t.integer :duration_ms
      
      # Erreurs
      t.text :error_message
      t.text :error_backtrace
      
      # Validation spécifique
      t.jsonb :validation_errors
      t.boolean :validation_success
      
      # Ordre associé
      t.references :order, foreign_key: true
      
      t.timestamps
    end
    
    # Index pour optimiser les requêtes
    add_index :api_logs, :request_id
    add_index :api_logs, :created_at
    add_index :api_logs, [:partner_id, :created_at]
    add_index :api_logs, [:endpoint, :created_at]
    add_index :api_logs, :validation_success
    add_index :api_logs, :status_code
  end
end
