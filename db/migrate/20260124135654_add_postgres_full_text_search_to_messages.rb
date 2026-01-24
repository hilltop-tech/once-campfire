class AddPostgresFullTextSearchToMessages < ActiveRecord::Migration[8.2]
  def up
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      # Create a simple table for PostgreSQL
      # Use a regular table instead of FTS5 virtual table
      create_table :message_search_index, id: false do |t|
        t.bigint :rowid, null: false
        t.text :body
      end
      add_index :message_search_index, :rowid, unique: true

      # Populate existing messages
      execute <<-SQL
        INSERT INTO message_search_index (rowid, body)
        SELECT id, body FROM action_text_rich_texts
        WHERE record_type = 'Message' AND name = 'body'
      SQL
    elsif ActiveRecord::Base.connection.adapter_name == 'SQLite'
      # For SQLite, create FTS5 virtual table
      execute <<-SQL
        CREATE VIRTUAL TABLE IF NOT EXISTS message_search_index USING fts5(body, tokenize=porter);
      SQL

      # Populate existing messages
      execute <<-SQL
        INSERT INTO message_search_index (rowid, body)
        SELECT id, body FROM action_text_rich_texts
        WHERE record_type = 'Message' AND name = 'body'
      SQL
    end
  end

  def down
    drop_table :message_search_index if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
    execute "DROP TABLE IF EXISTS message_search_index" if ActiveRecord::Base.connection.adapter_name == 'SQLite'
  end
end
