ActiveRecord::Schema.define do
  create_table(:users, force: true) do |t|
    t.string :first_name
    t.string :last_name
    t.string :email
    t.text :avatar
    t.timestamps null: false
  end
end
