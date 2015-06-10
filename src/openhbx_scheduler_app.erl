-module(openhbx_scheduler_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    Result = openhbx_scheduler_sup:start_link(),
    openhbx_scheduler_heartbeat:schedule_task(), 
    Result.

stop(_State) ->
    ok.
