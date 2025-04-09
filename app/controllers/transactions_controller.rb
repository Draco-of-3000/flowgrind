class TransactionsController < ApplicationController
  before_action :authenticate_user

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
    # Get the amount from params
    amount_in_dollars = params[:amount].to_i

    # Convert to subunits (cents, kobo, etc.) by multiplying by 100
    amount_in_subunits = amount_in_dollars * 100

    # Initialize transaction
    reference = "fg-#{Time.now.to_i}-#{current_user.id}"

    # Create a new transaction record (pending)
    @transaction = Transaction.create!(
      user: current_user,
      amount: amount_in_dollars,
      transaction_type: 'credit',
      paystack_reference: reference,
      status: 'pending'
    )

    # Initialize Paystack transaction
    result = PAYSTACK.transaction.initialize(
      email: current_user.email,
      amount: amount_in_subunits,
      reference: reference,
      callback_url: success_transactions_url
    )

    if result['status']
      # Redirect to Paystack payment page
      redirect_to result['data']['authorization_url'], allow_other_host: true
    else 
      # handle error
      @transaction.update(status: 'failed')
      flash[:alert] = "Could not initialize payment: #{result['message']}"
      redirect_to new_transaction_path
    end
  end

  def success
    # Get reference from Paystack callback
    reference = params[:reference]

    # Verify transaction with Paystack
    result = PAYSTACK.transaction.verify(reference)

    if result['status'] && result['data']['status'] == 'success'
      # Find the transaction
      transaction = Transaction.find_by(paystack_reference: reference)

      if transaction && transaction.status != 'completed'
        # Update transaction status
        transaction.update(status: 'completed')

        # Add credits to user
        current_user.credits += transaction.amount
        current_user.save 

        flash[:notice] = "Successfully added #{transaction.amount} credits to your account!"
      end
    else
      flash[:alert] = "Payment verification failed."
    end

    # Redirect to dashboard
    redirect_to dashboard_path
  end

  # Webhooks for asynchronous notifications from Paystack (optional, but recommended)
  def webhook
    # Verify webhook signature
    payload = request.body.read
    signature = request.headers['HTTP_X_PAYSTACK_SIGNATURE']
    
    # Verify webhook is from Paystack (very important for security)
    if verify_webhook(payload, signature)
      # Process the webhook data
      process_webhook(payload)
    end
    
    # Always return 200 to Paystack
    head :ok
  end
  
  private
  
  def verify_webhook(payload, signature)
    # Simple signature verification
    digest = OpenSSL::Digest.new('sha512')
    calculated_signature = OpenSSL::HMAC.hexdigest(digest, Rails.application.credentials.paystack[:secret_key], payload)
    
    Rack::Utils.secure_compare(calculated_signature, signature)
  end
  
  def process_webhook(payload)
    data = JSON.parse(payload)
    event = data['event']
    
    # Only process charge.success events
    if event == 'charge.success'
      reference = data['data']['reference']
      transaction = Transaction.find_by(paystack_reference: reference)
      
      if transaction && transaction.status != 'completed'
        transaction.update(status: 'completed')
        
        # Add credits to user
        user = transaction.user
        user.credits += transaction.amount
        user.save
      end
    end
  end
end
