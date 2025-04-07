class AddConfirmableAndTrackableToUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users do |t|
      # Confirmable columns
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      # Trackable columns
      t.integer  :sign_in_count, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
    end

    add_index :users, :confirmation_token, unique: true
  end
end
