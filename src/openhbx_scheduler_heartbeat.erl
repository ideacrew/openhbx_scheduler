-module(openhbx_scheduler_heartbeat).
-behaviour(gen_server).
-export([schedule_task/0,notify/0,code_change/3, handle_info/2, init/1, terminate/2, handle_cast/2, start_link/0, handle_call/3]).

-include("amqp_client.hrl").

start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

notify() -> gen_server:call(?MODULE, notify).

schedule_task() -> 
	leader_cron:schedule_task({sleeper, 60000},{openhbx_scheduler_heartbeat,notify,[]}).

init(_Args) -> openhbx_scheduler_amqp:parse_amqp_settings().

code_change(_OldVsn, State, _Extra) -> {ok, State}.

handle_info(_Info, State) -> {noreply, State}.

terminate(_Reason, _State) -> ok.

handle_cast(_Request, State) -> {noreply, State}.

handle_call(notify, _From, {Uri, ExchangeName}) ->
	case catch(openhbx_scheduler_amqp:send_notification(Uri,ExchangeName, constructPublish(ExchangeName), constructMessage())) of
		{error, A} -> {stop, {error, A}, {error, A}, {Uri, ExchangeName}};
		B -> B
	end.

constructPublish(ExchangeName) ->
  #'basic.publish'{routing_key = <<"info.events.calendar.heartbeat">>, exchange= list_to_binary(ExchangeName)}.

constructMessage() ->
  Payload = current_cron_list(),
  Props = #'P_basic'{
	  delivery_mode = 2,
	  timestamp = openhbx_scheduler_amqp:simple_timestamp()
  },
  #amqp_msg{props = Props, payload=Payload}.

current_cron_list() ->
	list_to_binary(io_lib:print(leader_cron:task_list())).
