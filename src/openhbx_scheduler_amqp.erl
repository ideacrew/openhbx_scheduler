-module(openhbx_scheduler_amqp).

-export([send_notification/4, parse_amqp_settings/0]).

-include("amqp_client.hrl").

send_notification(Uri, ExchangeName, PublishDetails, Message) ->
	{ok, Connection} = amqp_connection:start(Uri),
	{ok, Channel} = amqp_connection:open_channel(Connection),
	#'confirm.select_ok'{} = amqp_channel:call(Channel, #'confirm.select'{}),
	amqp_channel:register_confirm_handler(Channel, self()),
	ok = amqp_channel:call(Channel, PublishDetails, Message),
	Result = receive
		#'basic.ack'{}  -> {reply, ok, {Uri, ExchangeName}};
		_ -> {stop, publisher_confirm_failed,publisher_confirm_failed,{Uri, ExchangeName}}
          after
            2000 -> 
		   {stop, timeout_on_publisher_confirm,timeout_on_publisher_confirm,{Uri,ExchangeName}}
	end,
	amqp_channel:unregister_confirm_handler(Channel),
	amqp_connection:close(Connection),
	Result.

parse_amqp_settings() ->
	ConnectionSettings = application:get_env(openhbx_scheduler, amqp_uri),
	MessageSettings = application:get_env(openhbx_scheduler, exchange_name),
        case {ConnectionSettings,MessageSettings} of
		{undefined,_} -> {stop, amqp_connection_settings_missing};
		{_,undefined} -> {stop, day_change_settings_missing};
		{{ok, Val},{ok,DCS}} -> parseAmqpConnectionSpec(Val, DCS)
	end.

parseAmqpConnectionSpec(Settings, DayChangeSettings) -> 
	case amqp_uri:parse(Settings) of
	  {error, _} -> {stop, bad_amqp_uri};
	  {ok, Value} -> {ok, {Value, DayChangeSettings}}
	end.
