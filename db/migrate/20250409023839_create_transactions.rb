class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :transaction_type, null: false
      t.string :session_id  # Changed from references to string, no foreign key
      t.string :paystack_reference
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end

    add_index :transactions, :paystack_reference, unique: true
  end
end
