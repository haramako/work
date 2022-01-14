Sequel.migration do
  change do
    create_table :export_codes do
      primary_key :id
      Integer :user_id, null: false
      Integer :commit_num, null: false
      String :key64, null: false
      
      index [:user_id, :commit_num, :key64], unique: true
    end

  end
end
