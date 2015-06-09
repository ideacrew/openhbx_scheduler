-module(openhbx_scheduler_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    openhbx_scheduler_sup:start_link().

stop(_State) ->
    ok.
