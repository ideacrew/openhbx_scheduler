-module(openhbx_day_change).

-behaviour(gen_server).

-export([code_change/3, handle_info/2, init/1, terminate/2, handle_cast/2, handle_call/3, start_link/0, notify/0]).

-include("amqp_client.hrl").

start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

notify() -> gen_server:call(?MODULE, notify).

code_change(_OldVsn, State, _Extra) -> {ok, State}.

handle_info(_Info, State) -> {noreply, State}.

init(_Args) -> openhbx_scheduler_amqp:parse_amqp_settings().

terminate(_Reason, _State) -> ok.

handle_cast(_Request, State) -> {noreply, State}.

handle_call(notify, _From, {Uri, ExchangeName}) ->
	case catch(openhbx_scheduler_amqp:send_notification(Uri,ExchangeName, constructPublish(ExchangeName), constructMessage())) of
		{error, A} -> {stop, {error, A}, {error, A}, {Uri, ExchangeName}};
		B -> B
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
