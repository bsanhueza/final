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
  String :address
  Integer :capacity # max people that can play a game (no bench)
  Boolean :bbq # is there going to be an after game bbq party?
end
DB.create_table! :rsvps do
  primary_key :id
  foreign_key :event_id
  foreign_key :name_id
  Boolean :going
  Boolean :going_bbq
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
                    location: "La Caimanera Doral",
                    address: "8111 NW 54th St, Doral, FL 33166",
                    capacity: 12,
                    bbq: false)

events_table.insert(date: "June 24",
                    time: "20:00",
                    location: "Stadio Soccer Miami",
                    address: "571 NW 73rd St, Miami, FL 33150",
                    capacity: 14,
                    bbq: true)

events_table.insert(date: "June 27",
                    time: "09:00",
                    location: "Rooftop Soccer Brickell",
                    address: "444 Brickell Ave, Miami, FL 33131",
                    capacity: 10,
                    bbq: false)

events_table.insert(date: "June 30",
                    time: "16:00",
                    location: "MAST Academy Key Biscayne",
                    address: "3979 Rickenbacker Causeway, Miami, FL 33149",
                    capacity: 22,
                    bbq: true)