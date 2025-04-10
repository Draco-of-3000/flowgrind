class AddMetadataAndIpToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :metadata, :json
    add_column :transactions, :ip_address, :string
  end
end
