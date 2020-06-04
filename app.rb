# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "geocoder"                                                                    #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

events_table = DB.from(:events)
rsvps_table = DB.from(:rsvps)
users_table = DB.from(:users)

before do
    # SELECT * FROM users WHERE id = session[:user_id]
    @current_user = users_table.where(:id => session[:user_id]).to_a[0]
end

# Home page (all events)
get "/" do
    # before stuff runs
    @events = events_table.all
    view "events"
end

# Event page
get "/events/:id" do
    @users_table = users_table
    # SELECT * FROM events WHERE id=:id
    @event = events_table.where(:id => params["id"]).to_a[0]
    # SELECT * FROM rsvps WHERE event_id=:id
    @rsvps = rsvps_table.where(:event_id => params["id"]).to_a
    # SELECT COUNT(*) FROM rsvps WHERE event_id=:id AND going=1
    @count = rsvps_table.where(:event_id => params["id"], :going => true).count
    @lat_long = @event[:location]
    @attendance = rsvps_table.where(:event_id => params["id"], :name_id => @current_user[:id]).to_a[0]
    @bbq_aux = rsvps_table.where(:event_id => params["id"], :bbq_host => true).to_a[0]
    @bbq_person = users_table.where(:id => @bbq_aux[:name_id]).to_a[0]
    view "event"
end

# Create user
get "/users/new" do
    view "new_user"
end

# Receiving end of new user form
post "/users/create" do
    users_table.insert(:name => params["name"],
                       :email => params["email"],
                       :phone => params["phone"],
                       :password => BCrypt::Password.create(params["password"])) #Password encription
    view "create_user"
end

# Form to login
get "/logins/new" do
    view "new_login"
end

# Receiving end of login form
post "/logins/create" do
    email_entered = params["email"]
    password_entered = params["password"]
    # SELECT * FROM users WHERE email = email_entered
    user = users_table.where(:email => email_entered).to_a[0]
    if user
        # test the password against the one in the users table
        if BCrypt::Password.new(user[:password]) == password_entered
            session[:user_id] = user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else 
        view "create_login_failed"
    end
end

# Logout
get "/logout" do
    session[:user_id] = nil
    view "logout"
end

# Form to event
get "/event/new" do
    view "new_event"
end

# Receiving end of new event form
post "/event/create" do
    events_table.insert(:date => params["date"],
                       :time => params["time"],
                       :location => params["location"],
                       :capacity => params["capacity"],
                       :bbq => params["bbq"])
    view "create_event"
end

# Form to create a new RSVP
get "/events/:id/rsvps/new" do
    @event = events_table.where(:id => params["id"]).to_a[0]
    @count_bbq_host = rsvps_table.where(:event_id => params["id"], :bbq_host => true).count
    view "new_rsvp"
end

# Receiving end of new RSVP form
post "/events/:id/rsvps/create" do
    rsvps_table.insert(:event_id => params["id"],
                       :going => params["going"],
                       :going_bbq => params["going_bbq"],
                       :bbq_host => params["bbq_host"],
                       :name_id => @current_user[:id])
    view "create_rsvp"
end

