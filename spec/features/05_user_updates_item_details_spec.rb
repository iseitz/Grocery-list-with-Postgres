require "spec_helper"

feature "user updates item details" do
  scenario "see update item link on grocery item show page" do
    db_connection do |conn|
      sql_query_1 = "INSERT INTO groceries (name) VALUES ($1)"
      data_1 = ["eggs"]
      conn.exec_params(sql_query_1, data_1)
    end

    visit "/groceries"
    click_link "Update Item"

    expect(page).to have_content("Name")
  end

  scenario "go to the edit item page" do
    db_connection do |conn|
      sql_query_1 = "INSERT INTO groceries (name) VALUES ($1)"
      data_1 = ["eggs"]
      conn.exec_params(sql_query_1, data_1)

      sql_query_2 = "SELECT * FROM groceries WHERE name = $1"
      data_2 = ["eggs"]
      grocery_id = conn.exec_params(sql_query_2, data_2).first["id"]

      sql_query_3 = "INSERT INTO comments (body, grocery_id) VALUES ($1, $2)"
      data_3 = ["make sure they are fresh", grocery_id]
      conn.exec_params(sql_query_3, data_3)
    end

    visit "/groceries"
    click_link "Update Item"

    expect(page).to have_content("Name")
    expect(page).to have_content("Back to homepage")
  end

  scenario "visit edit item page and update item name" do

    db_connection do |conn|
      sql_query_1 = "INSERT INTO groceries (name) VALUES ($1)"
      data_1 = ["eggs"]
      conn.exec_params(sql_query_1, data_1)

      sql_query_2 = "SELECT * FROM groceries WHERE name = $1"
      data_2 = ["eggs"]
      @grocery_id = conn.exec_params(sql_query_2, data_2).first["id"]

      sql_query_3 = "INSERT INTO comments (body, grocery_id) VALUES ($1, $2)"
      data_3 = ["make sure they are fresh", @grocery_id]
      conn.exec_params(sql_query_3, data_3)
    end

    visit "/groceries/#{@grocery_id}/edit"
    expect(page).to have_field('name')
    expect(find_field('name').value).to eq 'eggs'

    find_field('name').value.clear
    fill_in 'name', with: 'Onions'
    click_button('Submit')

    expect(page).to have_content("Onions")
  end

end
