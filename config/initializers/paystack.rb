require 'paystack'

PAYSTACK = Paystack.new(Rails.application.credentials.paystack[:public_key], Rails.application.credentials.paystack[:secret_key])