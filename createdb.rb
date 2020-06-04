# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :events do
  primary_key :id
  String :date
  String :time
  String :location
end
DB.create_table! :rsvps do
  primary_key :id
  foreign_key :event_id
  foreign_key :name_id
  Boolean :going
  Boolean :bbq
  Boolean :bbq_host
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
  String :phone
end

# Insert initial (seed) data
events_table = DB.from(:events)

events_table.insert(date: "June 21",
                    time: "19:00",
                    location: "Rooftop Soccer Brickell")

events_table.insert(date: "June 24",
                    time: "20:00",
                    location: "Stadio Soccer Miami")
