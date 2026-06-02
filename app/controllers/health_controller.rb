class HealthController < ApplicationController
  skip_before_action :authenticate_request, only: [:show]
  def show
    begin
      # Execute a simple query to verify database connection and response
      result = ActiveRecord::Base.connection.execute("SELECT 1 AS alive").first

      if result && result["alive"].to_i == 1
        render json: {
          status: "ONLINE",
          database: {
            connected: true,
            result: result
          }
        }, status: :ok
      else
        render json: {
          status: "DEGRADED",
          database: {
            connected: false,
            error: "Unexpected query result"
          }
        }, status: :service_unavailable
      end
    rescue => e
      render json: {
        status: "OFFLINE",
        database: {
          connected: false,
          error: e.message
        }
      }, status: :service_unavailable
    end
  end
end
