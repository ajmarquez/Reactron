require 'rubygems'
require 'bundler/setup'
require 'slack-ruby-client'



### Class ReactionsList
#### This class manage the main array that has the reactions being tracked
#### remove => removes a tracked reaction
#### clear  => clears the tracked reactions array
#### show   => As the name explains, it shows the reactions
class ReactionList
  attr_accessor :array

  def initialize(array = [])
    @array = array
  end

  def remove(object=0)
    @array.delete(object)
  end

  def clear
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

## We create an instance of ReactionsList called main and set to 0
main = ReactionList.new(0)

## We create a variable called main_channel that saves the channel being used
main_channel = 0


### MESSAGE WRITTEN LOOP
## In order to feed the instructions to the Philbot to start track the reactions
## we must intercept the text written in the chat. For this (1) we detect when
## a :message is created.
##
## Next (2) we make sure that the message is of type 'text'. Other types are files, comment_files
## but this ones don't work for us
client.on :message do |data|
  puts data
  client.typing channel: data['channel']

  case data['text']

  ## To add a reaction list we set a series of commands:
  ##
  ## - When "philbot Track <reactions>" or "philbot track <reactions>" is written, next to a list of reactions separated by a blankspace
  ##   Philbot save this reactions as an array
  ## - When "philbot show" is written, a list of tracked reactions are showed
  ## - When "Hello philbot is written, a greeting message from the bot is produced nd explains who to introduce the reactions

when /^philbot [tT]rack (?<reactions>.*)$/ then
    ## Then match[:reactions] must be created into an array of reactions
    tracked_reactions = /^[tT]rack (?<reactions>.*)$/.match(data['text'])['reactions'].strip.split(" ")
    main.array = tracked_reactions
    client.message channel: data['channel'], text: "I'm phil-in your reactions!"
    main_channel = data['channel']

   #when /^[rR]emove (?<reactions>.*)$/ then
   #TO DO
   #Then another array is created and compared with the Main Reaction array, if matched delete from array. If not found, tell the use
   #client.message channel: data['channel'], text: "Reactions removed" # To be modified
 when 'philbot show' then
    ## Puts reactions being tracked
    client.message channel: data['channel'], text: "I'm keeping a eye on ---> #{main.show}"
  when 'hello philbot' then
    client.message channel: data['channel'], text: "Hi <@#{data['user']}>!, don't overREACT, ok? To add our reactions write 'track philbot' and add your reactions separated by a blanckspace."
  when 'philbot reset' then
    ## Delete reactions array
    main.clear
    puts "Reactions array cleared"

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
      client.message channel: main_channel, text: "And it's a match! http://i.imgur.com/QTGAq6N.gif "
    else
      puts "No match."
    end
  end
end


#To execute copy and paste this
# SLACK_API_TOKEN=xoxb-10237477606-qCNwWBSnmWiIvoVcWzPxorXm  bundle exec ruby philbot.rb


client.start!
