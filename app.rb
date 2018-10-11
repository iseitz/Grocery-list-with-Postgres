require "sinatra"
require "pg"
require "pry"

set :bind, '0.0.0.0'  # bind to all interfaces

configure :development do
  set :db_config, { dbname: "grocery_list_development" }
end

configure :test do
  set :db_config, { dbname: "grocery_list_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get "/" do
  redirect "/groceries"
end

get "/groceries" do
  @groceries = db_connection { |conn| conn.exec(
    'SELECT id, name
    FROM groceries;') }
  erb :groceries
end

post "/groceries" do
  if params["name"].nil?|| params["name"] == ""
    redirect"/groceries"
  else
    db_connection do |conn|
      name = params["name"]
      insert_data_groceries = "INSERT INTO groceries (name) VALUES ($1)"
      values_groceries = [name]
      conn.exec_params(insert_data_groceries, values_groceries)

      body = params["body"]
      all_groceries = conn.exec("SELECT * FROM groceries")
      groceries_array = all_groceries.to_a
      grocery_id = groceries_array.select{ |x| x["name"] == name}.first["id"]
      insert_data_comments = "INSERT INTO comments (body, grocery_id) VALUES ($1, $2)"
      values_comments = [body, grocery_id]
      conn.exec_params(insert_data_comments, values_comments)
    end
  end
  redirect "/groceries"
  erb :groceries
end


get "/groceries/:id" do
  @groceries = db_connection { |conn| conn.exec(
    'SELECT id, name
    FROM groceries;') }

  @comments = db_connection { |conn| conn.exec(
    'SELECT groceries.id AS id, name AS name, body AS comment
    FROM groceries
    JOIN comments
    ON groceries.id = comments.grocery_id;') }

  @all_comments = {}
  # {"name" => "potato", "comment1" => "something", "comment2" => "something else"}
  n = 1
  @comments.each do |comment|
    if params["id"].to_i == comment["id"].to_i && @all_comments["name"].nil?
      @all_comments["name"] = comment["name"]
      @all_comments["comment#{n}"] = comment["comment"]
    elsif params["id"].to_i == comment["id"].to_i && !@all_comments["name"].nil?
      if @all_comments["comment1"].nil? || @all_comments["comment1"] == ""
        @all_comments["comment#{n}"] = comment["comment"]
      elsif n < 5
        n += 1
        @all_comments["comment#{n}"] = comment["comment"]
      elsif n == 5
        if @all_comments["message"].nil?
          @all_comments["message"] = "Only 5 comments allowed, you already have #{n}!"
        end
      end
    end
  end
  erb :comments
end

# exceed expectations part:

delete "/groceries/:id" do
  if params["_method"] == 'DELETE'
    @id = params["id"].to_i
    db_connection  do |conn|
      remove_item = 'DELETE FROM groceries WHERE id = $1;'
      values = [@id]
      conn.exec_params(remove_item, values)
      params["_method"] = ''
    end
  end

  @groceries = db_connection { |conn| conn.exec(
    'SELECT id, name
    FROM groceries;') }
  erb :groceries
  redirect "/groceries"
end

post "/groceries/:id" do
  @groceries = db_connection { |conn| conn.exec(
    'SELECT id, name
    FROM groceries;') }
  erb :groceries
  redirect "/groceries"
end

get "/groceries/:id/edit" do
  @groceries = db_connection { |conn| conn.exec(
    'SELECT id, name
    FROM groceries;') }
  @groceries.each do |item|
    if params["id"].to_i == item["id"].to_i
      @name = item["name"]
    end
  end

  @comments = db_connection { |conn| conn.exec(
    'SELECT groceries.id AS id, name AS name, body AS comment
    FROM groceries
    JOIN comments
    ON groceries.id = comments.grocery_id;') }
  erb :edit
end

patch "/groceries/:id/edit" do

  if params["name"] == "" || params["name"].nil? || params["name"] ==" " || params["name"] =="  "
    @id = params["id"].to_i
    redirect "/groceries/#{@id}/edit"
  else
    @item_name = params["name"]
    @item_id = params["id"].to_i
    @items = db_connection { |conn| conn.exec(
      'SELECT groceries.id AS id, name AS name
      FROM groceries;') }
    @item_to_update = @items.select {|item| item["id"].to_i == @item_id}

    db_connection do |conn|
      update_data_groceries = "UPDATE groceries SET name=$1 WHERE id = $2"
      values_groceries = [@item_name, @item_id]
      conn.exec_params(update_data_groceries, values_groceries)

      @groceries = db_connection { |conn| conn.exec(
       'SELECT id, name
        FROM groceries;') }

        erb :edit
        redirect "/groceries"
    end
  end
end

patch "/groceries/:id/add-comment" do

  if params["comment"] == "" || params["comment"].nil? || params["comment"] ==" " || params["comment"] =="  "
    @id = params["id"].to_i
    redirect "/groceries/#{@id}/add-comment"
  else
    @comment_body = params["comment"]
    @grocery_id = params["id"].to_i
      db_connection do |conn|
        update_data_groceries = "INSERT INTO comments (body, grocery_id) VALUES ($1, $2)"
        values_comment = [@comment_body, @grocery_id]
        conn.exec_params(update_data_groceries, values_comment)

        @groceries = db_connection { |conn| conn.exec(
          'SELECT id, name
          FROM groceries;') }

        erb :add_comment
        redirect "/groceries"
      end

  end
end

get "/groceries/:id/add-comment" do
  @groceries = db_connection { |conn| conn.exec(
    'SELECT id, name
    FROM groceries;') }
  @groceries.each do |item|
    if params["id"].to_i == item["id"].to_i
      @name = item["name"]
    end
  end

  @comments = db_connection { |conn| conn.exec(
    'SELECT groceries.id AS id, name AS name, body AS comment
    FROM groceries
    JOIN comments
    ON groceries.id = comments.grocery_id;') }
  erb :add_comment
end
