class LinebotController < ApplicationController
  before_action :getData

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'rexml/document'

  protect_from_forgery :except => [:callback]

  def getData
    uri = URI.parse("https://www.healthplanet.jp/status/innerscan.json?access_token=#{ENV["TANITA_TOKEN"]}&date=1&tag=6021")
    json = Net::HTTP.get(uri)
    result = JSON.parse(json)
    @data = result['data']
    @d1 = @data[0]
    @d2 = @data[1]
    # @lasttime = Time.parse(@d1['date'])
    @op = (@d1 - @d2 >= 0 ? '+' : '')
    @weight = @d1 - @d2
  end

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text

          # case event.message['text']
          # when '体重'
            message = [{
              type: 'text',
              # text: '体重だよ'
              text: "最後の測定： #{@d1['keydata']}kg\nその前： #{@d2['keydata']}kg"
            },{
              type: 'text',
              text: "前回から#{@op}#{@weight}kgだよ" 
            },]
          client.reply_message(event['replyToken'], message)
          # else
          #   message = {
          #     type: 'text',
          #     text: event.message['text']
          #   }
          # client.reply_message(event['replyToken'], message)
          # end
        end
      end
    }

    head :ok
  end
end
