class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.string :token, index: {unique: true}
      t.references :user
      t.string :service
      t.timestamps null: false
    end

  end
end
