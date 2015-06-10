-module(openhbx_day_change).

-behaviour(gen_server).

-export([code_change/3, handle_info/2, init/1, terminate/2, handle_cast/2, handle_call/3, start_link/0, notify/0]).

-include("amqp_client.hrl").

start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

notify() -> gen_server:call(?MODULE, notify).

code_change(_OldVsn, State, _Extra) -> {ok, State}.

handle_info(_Info, State) -> {noreply, State}.

%% TODO: Pull amqp settings from app environment.
init(_Args) -> 
	ConnectionSettings = application:get_env(openhbx_scheduler, amqp_uri),
	MessageSettings = application:get_env(openhbx_scheduler, exchange_name),
        case {ConnectionSettings,MessageSettings} of
		{undefined,_} -> {stop, amqp_connection_settings_missing};
		{_,undefined} -> {stop, day_change_settings_missing};
		{{ok, Val},{ok,DCS}} -> parseAmqpConnectionSpec(Val, DCS)
	end.

terminate(_Reason, _State) -> ok.

handle_cast(_Request, State) -> {noreply, State}.

send_notification(Uri, ExchangeName) ->
	{ok, Connection} = amqp_connection:start(Uri),
	{ok, Channel} = amqp_connection:open_channel(Connection),
	#'confirm.select_ok'{} = amqp_channel:call(Channel, #'confirm.select'{}),
	amqp_channel:register_confirm_handler(Channel, self()),
	ok = amqp_channel:call(Channel, constructPublish(ExchangeName), constructMessage()),
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

handle_call(notify, _From, {Uri, ExchangeName}) ->
	case catch(send_notification(Uri,ExchangeName)) of
		{error, A} -> {stop, {error, A}, {error, A}, {Uri, ExchangeName}};
		B -> B
	end.


parseAmqpConnectionSpec(Settings, DayChangeSettings) -> 
	case amqp_uri:parse(Settings) of
	  {error, _} -> {stop, bad_amqp_uri};
	  {ok, Value} -> {ok, {Value, DayChangeSettings}}
	end.

constructPublish(ExchangeName) ->
  #'basic.publish'{routing_key = <<"info.events.calendar.date_change">>, exchange= list_to_binary(ExchangeName)}.

constructMessage() ->
  Props = #'P_basic'{
	  delivery_mode = 2,
	  headers = [
		  {<<"current_date">>, longstr, formatCurrentDate()} 
  ]},
  #amqp_msg{props = Props}.

formatCurrentDate() ->
	{{Year, Month, Day},_} = calendar:universal_time(),
	list_to_binary(io_lib:format("~w-~2..0w-~2..0w", [Year,Month,Day])).
