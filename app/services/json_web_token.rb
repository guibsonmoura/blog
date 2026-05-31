class JsonWebToken
  ALGORITHM = "HS256"
  ISSUER = "blog-admin"

  class << self
    def encode(payload = {}, expires_at: 12.hours.from_now, issuer: ISSUER, **claims)
      token_claims = payload.merge(claims).merge(exp: expires_at.to_i, iss: issuer)
      JWT.encode(token_claims, secret, ALGORITHM)
    end

    def decode(token, issuer: ISSUER)
      body, = JWT.decode(
        token,
        secret,
        true,
        algorithm: ALGORITHM,
        iss: issuer,
        verify_iss: true
      )

      body.with_indifferent_access
    rescue JWT::DecodeError
      nil
    end

    private

    def secret
      ENV.fetch("JWT_SECRET", Rails.application.secret_key_base)
    end
  end
end
