-module(openhbx_day_change).

-behaviour(gen_server).

-export([code_change/3, handle_info/2, init/1, terminate/2, handle_cast/2, handle_call/3]).

-include("amqp_client.hrl").

code_change(_OldVsn, State, _Extra) -> {ok, State}.

handle_info(_Info, State) -> {noreply, State}.

%% TODO: Pull amqp settings from app environment.
init(_Args) -> 
	ConnectionSettings = application:get_key(openhbx_scheduler, amqp_uri),
	MessageSettings = application:get_key(openhbx_scheduler, exchange_name),
        case {ConnectionSettings,MessageSettings} of
		{undefined,_} -> {stop, amqp_connection_settings_missing};
		{_,undefined} -> {stop, day_change_settings_missing};
		{{ok, Val},{ok,DCS}} -> parseAmqpConnectionSpec(Val, DCS)
	end.

terminate(_Reason, _State) -> ok.

handle_cast(_Request, State) -> {noreply, State}.

handle_call(notify, _From, {Uri, ExchangeName}) -> 
	{ok, Connection} = amqp_connection:start(Uri),
	{ok, Channel} = amqp_connection:open_channel(Connection),
	#'confirm.select_ok'{} = amqp_channel:call(Channel, #'confirm.select'{}),
	amqp_channel:register_confirm_handler(Channel, self()),
	Result = receive
		#'basic.ack'{}  -> {noreply, {Uri, ExchangeName}};
		_ -> {stop, publisher_confirm_failed,{Uri, ExchangeName}}
          after
            3000 -> {stop, timeout_on_publisher_confirm,{Uri,ExchangeName}}
	end,
	amqp_channel:call(channel, constructPublish(ExchangeName), constructMessage()),
	amqp_channel:unregister_confirm_handler(Channel),
	amqp_connection:close(Connection),
	Result.


parseAmqpConnectionSpec(Settings, DayChangeSettings) -> 
	case amqp_uri:parse(Settings) of
	  {error, _} -> {stop, bad_amqp_uri};
	  {ok, Value} -> {ok, {Value, DayChangeSettings}}
	end.

constructPublish(ExchangeName) ->
  #'basic.publish'{routing_key = <<"info.events.calendar.date_change">>, exchange= ExchangeName}.

constructMessage() ->
  Props = #'P_basic'{
	  delivery_mode = 2,
	  headers = [
	  {<<"current_date">>, longstr, ohbx_day_change_schedule:yesterday()} 
  ]},
  #amqp_msg{props = Props}.
