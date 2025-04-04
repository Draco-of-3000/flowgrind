class AddDetailsToUsers < ActiveRecord::Migration[8.0]
  def change
    # User Information
    add_column :users, :username, :string
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :profile_image, :string
    add_column :users, :timezone, :string, default: "UTC"
    
    # Financial Management
    add_column :users, :credits, :decimal, precision: 10, scale: 2, default: 5.0
    add_column :users, :total_earned, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :users, :total_lost, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :users, :paystack_customer_id, :string
    
    # Analytics (if not already added by Devise trackable)
    add_column :users, :completed_sessions_count, :integer, default: 0
    add_column :users, :successful_validations_count, :integer, default: 0
    add_column :users, :failed_validations_count, :integer, default: 0
    
    # Indexes for faster lookups
    add_index :users, :username, unique: true
    add_index :users, :paystack_customer_id
  end
end
