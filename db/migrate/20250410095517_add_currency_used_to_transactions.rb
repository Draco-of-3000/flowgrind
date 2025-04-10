class AddCurrencyUsedToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :currency_used, :string
  end
end
