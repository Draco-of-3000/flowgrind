class AddBrowserFingerprintToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :browser_fingerprint, :string
  end
end
