$: << File.dirname(__FILE__)
require 'goliath'
require 'pubsub'
#require 'awesome_print'

 
class SSE < Goliath::API

#  use Rack::Static, :urls => ["/index.html"], :root => Goliath::Application.app_path("public")

@@myenv = nil

  # handles all connection close events
  def on_close(env)
    Pubsub.callbacks(:on_close) { |callback| callback.call(env) }
  end

  def response(env)

    logger.info "env request path = #{env['REQUEST_PATH']}"
    if env['REQUEST_PATH'] == '/'
      @@myenv = env
      [200, {'Content-Type' => 'text/html'}, File.open('public/index.html').read()]
#    elsif env['REQUEST_PATH'] == '/events'
#      logger.info "start response"
#      streaming_response(200, {'Content-Type' => 'text/event-stream'})
    elsif env['REQUEST_PATH'] == '/0'
      @@myenv.stream_send("data:hello ##{rand(100)}\n\n") 
    elsif env['REQUEST_PATH'] == '/1'
      @@myenv.stream_send(["event:signup", "data:signup event ##{rand(100)}\n\n"].join("\n"))
    elsif env['REQUEST_PATH'] == '/events'
      unless env['HTTP_ACCEPT'] == 'text/event-stream'
        return [ 406, { }, [ ] ]
      end
        
      sub_id = Pubsub.channel.subscribe do |msg|
        env.stream_send("data:hello #{msg}\n\n")
      end
    
      env['pubsub.subscriber.id'] = sub_id
   
      logger.info "sub_id = #{sub_id}"

      Pubsub.callback(:on_close, sub_id) do |e|
        if e['pubsub.subscriber.id'] == sub_id
          Pubsub.channel.unsubscribe(sub_id)
          Pubsub.remove(:on_close, sub_id)
        end
      end
    
      streaming_response(200, { 'Content-Type' => "text/event-stream" })
    elsif env['REQUEST_PATH'] == '/message'
      Pubsub.channel.pushone(2, "data:broadcasting message..\n\n")
      [ 200, { }, [ ] ]
    end
  end
end


