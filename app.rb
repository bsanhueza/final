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
    @count = rsvps_table.where(:event_id => params["id"], :going => "true").count
    results = Geocoder.search(@event[:address])
    @lat_long = results.first.coordinates.join(",")
    if @current_user
        @attendance = rsvps_table.where(:event_id => params["id"], :name_id => @current_user[:id]).to_a[0]
    end
    @bbq_aux = rsvps_table.where(:event_id => params["id"], :bbq_host => "true").to_a[0]
    if @bbq_aux
        @bbq_person = users_table.where(:id => @bbq_aux[:name_id]).to_a[0]
    end
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
                       :address => params["address"],
                       :capacity => params["capacity"],
                       :bbq => params["bbq"])
    view "create_event"
end

# Form to create a new RSVP
get "/events/:id/rsvps/new" do
    @event = events_table.where(:id => params["id"]).to_a[0]
    @count_bbq_host = rsvps_table.where(:event_id => params["id"], :bbq_host => "true").count
    view "new_rsvp"
end

# Receiving end of new RSVP form
post "/events/:id/rsvps/create" do
    rsvps_table.insert(:event_id => params["id"], # Event ID
                       :going => params["going"], # Going to play or not?
                       :going_bbq => params["going_bbq"], # Going to the after game BBQ or not?
                       :bbq_host => params["bbq_host"], # BBQ leader or not?
                       :name_id => @current_user[:id]) # Name of the logged-in user
    @event = events_table.where(:id => params["id"]).to_a[0] # Current event details
    #Twilio only works with +1 305 570 9056
     if @current_user[:phone] == "3055709056"
        account_sid = ENV["TWILIO_ACCOUNT_SID"]
        auth_token = ENV["TWILIO_AUTH_TOKEN"]
        client = Twilio::REST::Client.new(account_sid,auth_token)
        client.messages.create(
            from: "+12566458516",
            to: "+1#{@current_user[:phone]}",
            body: "Dear #{@current_user[:name]}, you've RSVP'd to play pickup soccer: #{@event[:location]}, 
                  #{@event[:date]} at #{@event[:time]}!"
        )
    end  
    view "create_rsvp"
end

