require 'rubygems'
require 'bundler/setup'
require 'slack-ruby-client'



class ReactionList
  attr_accessor :array

  def initialize(array = [])
    @array = array
  end

  def clear!
    @array = []
  end

  def show
    @array.join(' ')
  end

end



## First we configure the Slack client and feed the Token
Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  fail 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end


client = Slack::RealTime::Client.new
main = ReactionList.new([])
main_channel = ""
bot_name = client.web_client.rtm_start['self']['name']



client.on :message do |data|
  puts data
  client.typing channel: data['channel']

  if data['text'] then
    is_admin = client.web_client.users_info(user: data['user'])['user']['is_admin']
  end

  case data['text']


  when /^#{bot_name} [tT]rack (?<reactions>.*)$/ then

    if is_admin == true then
      main.array = /^#{bot_name} [tT]rack (?<reactions>.*)$/.match(data['text'])['reactions'].strip.split(" ")
      client.message channel: data['channel'], text: "I'm tracking your reactions"
      main_channel = data['channel']
    else
      client.message channel: data['channel'], text: "You are not authorize for this action."
    end

  when /^#{bot_name} show$/ then

   if is_admin == true then
     if !main.array.empty? then
       client.message channel: data['channel'], text: "I'm currently tracking => #{main.show}"
     else
       client.message channel: data['channel'], text: "There are no reactions being tracked"
     end
   else
     client.message channel: data['channel'], text: "You are not authorize for this action."
   end

  when /^hello #{bot_name}$/ then

    if is_admin == true then
      client.message channel: data['channel'], text: "Hello <@#{data['user']}>, I'm ready to begin! "
    else
      client.message channel: data['channel'], text: "Hello <@#{data['user']}>. I'm sorry but you are not authorize to track reactions"
    end

  when /^#{bot_name} reset$/ then
    ## Delete reactions array
    if is_admin == true then
      main.clear!
      client.message channel: data['channel'], text: "Reactions are cleared"
    else
      client.message channel: data['channel'], text: "You are not authorize for this action."
    end
  end
end


### REACTION ADDED LOOP
## In order to recognize when a reaction  happens and check if the array of reactions match,
## we listen for a reaction.add event.
##
## Once is made we do the following tasks:
## (1) Retrieve from the reaction.add message its timestamp and we execute a method from the Web API called
##     reactions.get to retrieve all the reactions associated to the message on which a reaction was recently added
## (2) We same that array
## (3) We compare it to the main array
## (4) If they match, present a .gif of Phil giving you a thumbs up, else do nothing

client.on :reaction_added do |data|

  dummy_list = []

  if main_channel!=0 then

    r_message = client.web_client.reactions_get(channel: main_channel, timestamp: data['item']['ts']) #(1)
    r_reactions = r_message['message']['reactions'] #Reactions from reacted message

    r_reactions.each do |item|
      dummy_list.push(":#{item['name']}:") #(2)
    end

    if dummy_list.sort == main.array.sort then   #(3) and (4)
      puts "THEY MATCH!"
      client.message channel: main_channel, text: "And it's a match! "
    else
      puts "No match."
    end
  end
end


#To execute copy and paste this
# SLACK_API_TOKEN=xoxb-10237477606-qCNwWBSnmWiIvoVcWzPxorXm  bundle exec ruby reactron.rb


client.start!
