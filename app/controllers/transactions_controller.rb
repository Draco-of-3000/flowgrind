class TransactionsController < ApplicationController
  before_action :authenticate_user!
  rescue_from StandardError, with: :handle_payment_error
  
  # Tolerance percentage for amount verification (5%)
  AMOUNT_TOLERANCE_PERCENTAGE = 0.05
  
  def new
    # Pre-defined credit packages
    @credit_packages = [
      { amount: 5, price: 5 },
      { amount: 10, price: 10 },
      { amount: 20, price: 20 },
      { amount: 50, price: 45 } # $5 discount for bulk purchase
    ]
  end
  
  def create
    # Get the amount with proper precision
    amount_in_dollars = BigDecimal(params[:amount].to_s)
    
    # Validate minimum amount
    if amount_in_dollars < 1
      flash[:alert] = "Amount must be at least $1."
      return redirect_to new_transaction_path
    end
    
    # Convert to subunits with proper precision
    amount_in_subunits = (amount_in_dollars * 100).to_i
    
    # Initialize transaction with secure reference
    reference = "fg-#{SecureRandom.hex(8)}-#{current_user.id}"
    
    # Generate browser fingerprint
    browser_fingerprint = generate_browser_fingerprint(request)
    
    # Create a new transaction record (pending)
    @transaction = Transaction.create!(
      user: current_user,
      amount: amount_in_dollars,
      transaction_type: 'credit',
      paystack_reference: reference,
      status: 'pending',
      ip_address: request.remote_ip,
      browser_fingerprint: browser_fingerprint
    )
    
    # Initialize Paystack transaction
    result = PAYSTACK.transaction.initialize(
      email: current_user.email,
      amount: amount_in_subunits,
      reference: reference,
      callback_url: success_transactions_url
    )
    
    if result['status']
      # Store initialization response
      @transaction.record_metadata(result['data'])
      
      # Redirect to Paystack payment page
      redirect_to result['data']['authorization_url'], allow_other_host: true
    else
      # Handle error
      @transaction.update(status: 'failed', metadata: result.to_json)
      flash[:alert] = "Could not initialize payment: #{result['message']}"
      redirect_to new_transaction_path
    end
  end
  
  def success
    reference = params[:reference]
    
    # Find existing transaction first (idempotency)
    transaction = Transaction.find_by(paystack_reference: reference)
    
    # Only proceed if transaction exists and isn't already completed
    if transaction && transaction.status != 'completed'
      # Verify with Paystack
      begin
        result = PAYSTACK.transaction.verify(reference)
        
        if result['status'] && result['data']['status'] == 'success'
          # Log the currency used (for analytics/audit)
          transaction_currency = result['data']['currency']
          actual_amount = result['data']['amount'].to_i
          expected_amount = (transaction.amount * 100).to_i
          
          # Calculate acceptable amount range with tolerance
          min_acceptable = (expected_amount * (1 - AMOUNT_TOLERANCE_PERCENTAGE)).to_i
          max_acceptable = (expected_amount * (1 + AMOUNT_TOLERANCE_PERCENTAGE)).to_i
          
          # Check if amount is within acceptable range
          if actual_amount >= min_acceptable && actual_amount <= max_acceptable
            # Amount is within tolerance - proceed with completion
            
            # Calculate exact difference for audit purposes
            amount_difference = actual_amount - expected_amount
            amount_difference_percentage = (amount_difference.to_f / expected_amount) * 100
            
            # Log the difference for reconciliation
            Rails.logger.info(
              "PAYMENT CONVERSION: Transaction #{transaction.id} " +
              "Expected: #{expected_amount}, Received: #{actual_amount}, " +
              "Difference: #{amount_difference} (#{amount_difference_percentage.round(2)}%), " +
              "Currency: #{transaction_currency}"
            )
            
            # Update transaction with verification data and currency info
            transaction.update(
              status: 'completed',
              metadata: result['data'].to_json,
              currency_used: transaction_currency,
              amount_received: actual_amount / 100.0  # Store actual amount received for accounting
            )
            
            # Atomically update user credits and total earned
            # We credit the user with what they paid for, not the actual amount received
            transaction.user.with_lock do
              User.where(id: transaction.user_id).update_all(
                "credits = credits + #{transaction.amount}, " +
                "total_earned = total_earned + #{transaction.amount}"
              )
            end
            
            flash[:notice] = "Successfully added #{transaction.amount} credits to your account!"
          else
            # Amount outside of tolerance - flag for review
            log_amount_discrepancy(transaction, actual_amount, expected_amount, transaction_currency)
            
            # If amount is higher than expected, it's likely not fraud but still needs review
            if actual_amount > max_acceptable
              status = 'amount_higher'
              flash[:alert] = "Payment verification issue. Your payment appears to be higher than expected. Our team will review and credit your account accordingly."
            else
              status = 'amount_lower'
              flash[:alert] = "Payment verification issue. Please contact support with reference: #{reference}"
            end
            
            transaction.update(
              status: status,
              metadata: result['data'].to_json,
              currency_used: transaction_currency,
              amount_received: actual_amount / 100.0  # Store for reconciliation
            )
          end
        else
          # Payment failed validation from Paystack
          transaction.update(status: 'failed', metadata: result.to_json)
          flash[:alert] = "Payment verification failed."
        end
      rescue => e
        # Log error and show friendly message
        log_error(e, transaction)
        flash[:alert] = "We couldn't verify your payment. Please contact support."
      end
    end
    
    # Redirect to dashboard
    redirect_to dashboard_path
  end
  
  def webhook
    # Verify webhook signature and IP
    payload = request.body.read
    signature = request.headers['HTTP_X_PAYSTACK_SIGNATURE']
    
    # Verify webhook is from Paystack
    if verify_webhook(payload, signature)
      # Process the webhook data
      data = JSON.parse(payload)
      event = data['event']
      
      # Only process charge.success events
      if event == 'charge.success'
        reference = data['data']['reference']
        transaction = Transaction.find_by(paystack_reference: reference)
        
        # Ensure idempotency
        if transaction && transaction.status != 'completed'
          # Update browser fingerprint for additional tracking
          browser_fingerprint = generate_browser_fingerprint(request)
          transaction.update(browser_fingerprint: browser_fingerprint)
          
          # Verify amount is within acceptable range
          transaction_currency = data['data']['currency']
          actual_amount = data['data']['amount'].to_i
          expected_amount = (transaction.amount * 100).to_i
          
          # Calculate acceptable amount range with tolerance
          min_acceptable = (expected_amount * (1 - AMOUNT_TOLERANCE_PERCENTAGE)).to_i
          max_acceptable = (expected_amount * (1 + AMOUNT_TOLERANCE_PERCENTAGE)).to_i
          
          if actual_amount >= min_acceptable && actual_amount <= max_acceptable
            # Calculate exact difference for audit purposes
            amount_difference = actual_amount - expected_amount
            amount_difference_percentage = (amount_difference.to_f / expected_amount) * 100
            
            # Log the difference for reconciliation
            Rails.logger.info(
              "WEBHOOK PAYMENT CONVERSION: Transaction #{transaction.id} " +
              "Expected: #{expected_amount}, Received: #{actual_amount}, " +
              "Difference: #{amount_difference} (#{amount_difference_percentage.round(2)}%), " +
              "Currency: #{transaction_currency}"
            )
            
            # Update transaction status, metadata, and currency info
            transaction.update(
              status: 'completed',
              metadata: data['data'].to_json,
              currency_used: transaction_currency,
              amount_received: actual_amount / 100.0  # Store actual amount received
            )
            
            # Atomically update user credits and total earned
            transaction.user.with_lock do
              User.where(id: transaction.user_id).update_all(
                "credits = credits + #{transaction.amount}, " +
                "total_earned = total_earned + #{transaction.amount}"
              )
            end
          else
            # Amount outside of tolerance - flag for review
            log_amount_discrepancy(transaction, actual_amount, expected_amount, transaction_currency)
            
            # Determine appropriate status based on direction of discrepancy
            status = actual_amount > max_acceptable ? 'amount_higher' : 'amount_lower'
            
            transaction.update(
              status: status,
              metadata: data.to_json,
              currency_used: transaction_currency,
              amount_received: actual_amount / 100.0
            )
          end
        end
      end
    else
      # Invalid signature - log potential attack attempt
      Rails.logger.warn("Invalid Paystack webhook signature detected from IP: #{request.remote_ip}")
    end
    
    # Always return 200 to Paystack
    head :ok
  end
  
  private
  
  def verify_webhook(payload, signature)
    # Validate IP first
    return false unless valid_paystack_ip?(request.remote_ip)
    
    # Then perform signature verification
    digest = OpenSSL::Digest.new('sha512')
    expected_signature = OpenSSL::HMAC.hexdigest(
      digest, 
      Rails.application.credentials.paystack[:secret_key], 
      payload
    )
    
    # Constant-time comparison to prevent timing attacks
    Rack::Utils.secure_compare(expected_signature, signature)
  end
  
  def valid_paystack_ip?(ip)
    # Get updated IP ranges from: https://developers.paystack.co/docs/ips
    paystack_ips = ['52.31.139.75', '52.49.173.169', '52.214.14.220']
    paystack_ips.any? { |range| IPAddr.new(range).include?(ip) }
  end
  
  def generate_browser_fingerprint(request)
    user_agent = request.user_agent || 'unknown'
    ip = request.remote_ip || 'unknown'
    
    # Create a fingerprint based on user agent and IP
    Digest::SHA256.hexdigest("#{user_agent}-#{ip}")
  end
  
  def log_amount_discrepancy(transaction, actual, expected, currency)
    difference = actual - expected
    difference_percentage = (difference.to_f / expected) * 100
    
    Rails.logger.warn(
      "AMOUNT DISCREPANCY: Transaction #{transaction.id} " +
      "for user #{transaction.user_id}. " +
      "Expected: #{expected}, Received: #{actual}, " +
      "Difference: #{difference} (#{difference_percentage.round(2)}%), " +
      "Currency: #{currency}, IP: #{request.remote_ip}"
    )
  end
  
  def handle_payment_error(exception)
    @transaction&.update!(status: 'failed')
    log_error(exception)
    flash[:alert] = "We encountered an error while processing your payment. Please try again."
    redirect_to new_transaction_path
  rescue => e
    # Fallback if even error handling fails
    Rails.logger.error("Critical error in payment processing: #{e.message}")
    flash[:alert] = "Something went wrong. Please try again later."
    redirect_to dashboard_path
  end
  
  def log_error(exception, transaction = nil)
    transaction_id = transaction&.id || @transaction&.id
    
    Rails.logger.error(
      "Payment Error: #{exception.message} | " +
      "User: #{current_user.id} | " +
      "Transaction: #{transaction_id} | " +
      "IP: #{request.remote_ip} | " +
      "UA: #{request.user_agent}"
    )
  end
end