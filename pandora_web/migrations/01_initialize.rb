Sequel.migration do
  change do
    create_table :users do
      Integer :id, primary_key: true
      String :session_key, null: false
      Integer :last_commit, null: false
      String :name, null: false
    end
    
    create_table :commits do
      Integer :user_id, null: false
      Integer :num, null: false
      Integer :commit_type, null: false

      DateTime :mtime, null: false
      
      primary_key [:user_id, :num, :commit_type]
    end
  end
end
