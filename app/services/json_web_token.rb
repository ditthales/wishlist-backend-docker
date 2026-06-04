class JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base

  # Encodes the payload with an expiration time (default: 30 days)
  def self.encode(payload, exp = 30.days.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  # Decodes the token and returns the payload, or nil if invalid/expired
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError
    nil
  end
end
