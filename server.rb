require "sinatra/base"
require "pg"
require "bcrypt"
require "pry"
require "redcarpet"

# markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      # md = markdown.render(params[ "topics" ])

module Kung_Fu
	class Server < Sinatra::Base


		enable :sessions

		def current_user 
			db = database_connection
			if session["user_id"]
				@current_user ||= db.exec_params(<<-SQL, [session["user_id"]]).first 
				SELECT * FROM users WHERE id = $1
				SQL
	    end
		end

		get "/" do
			db = database_connection
			@topics = db.exec_params("SELECT * FROM topics")
			erb :index
		end

		get "/users/:id" do
			db = database_connection
			@users = db.exec_params("SELECT * FROM users WHERE id = $1", [params[:id]])
			@topic_users = db.exec_params("SELECT * FROM topics WHERE topics.user_id = $1", [params[:id]])
			erb :users_page
		end

		get "/signup" do
			erb :signup
		end
# params is getting the params of a search and returning to you a general assortment of stuff within the params of what you typed.
		post "/signup" do
			db = database_connection
			@fname = params[:fname]
			@lname = params[:lname]
			encrypted_password = BCrypt::Password.create(params[:login_password])
			users = db.exec_params(<<-SQL, [params[:login_name], encrypted_password, @fname, @lname]) 
			INSERT INTO users (login_name, login_password, fname, lname) VALUES ($1, $2, $3, $4) RETURNING id, fname, lname;
			SQL

			redirect "/users/#{users.first["id"]}"
		end

		get "/signin" do
		end

		
		post "/signin" do
			db = database_connection
			@user = db.exec_params("SELECT * FROM users WHERE login_name = $1", [params["login_name"]]).first

			if @user && BCrypt::Password.new(@user["login_password"]) == params["login_password"]
				session["user_id"] = @user["id"]
				redirect "/users/#{@user['id']}"
				erb :index
			else
				redirect "/"
			end
		end

		get "/topics" do
		db = database_connection 
			@topics = db.exec_params("SELECT * FROM topics")
			erb :topics
		end


		get "/topics/form" do
			erb :topics_form
		end

		post "/topics/form" do
			# binding.pry
			db = database_connection
			
			db.exec_params(<<-SQL, [session["user_id"], params["titles"], params["topic_text"]])
					INSERT INTO topics (user_id, titles, topic_text) VALUES ($1, $2, $3)
			SQL

			@topic_submitted = true

			redirect "/topics"
			

		end

		get "/topics/:id" do
			# I want to display the comments on the topics here. 
			db = database_connection
			@comment_topics = params[:id]
			@users_comment = db.exec_params("SELECT * FROM comments WHERE comments.user_id = $1", [params[:id]]).first
			# @users = db.exec_params("SELECT * FROM users WHERE id = $1", [params[:id]]).first

			@view_topic = db.exec_params("SELECT * FROM topics WHERE id = $1", [params[:id]]).first

			@comments_display = db.exec_params("SELECT * FROM comments WHERE comments.topic_id = $1", [params[:id]])
			# @comments = db.exec_params("SELECT * FROM comments")

			erb :view_topic
		end

		post "/comments" do
			db = database_connection
			db.exec_params(<<-SQL, [params['topic_id'].to_i, params["content"], session["user_id"]])
				INSERT INTO comments (topic_id, content, user_id) VALUES ($1, $2, $3)
			SQL

			redirect "/topics/#{params[:topic_id]}"
	
			erb :view_topic
		end

		get "/logout" do
			session.clear
			redirect "/"
		end

		delete "/logout" do
			session.clear
			redirect "/"
		end
		
		private

		# use this for smaller projects, but if it were a bigger project use 
		# @@db = PG,connect(dbnmae: "name of db")
		def database_connection
			PG.connect(dbname: "Kung_Fu")
		end

	end
end



