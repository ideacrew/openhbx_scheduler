-module(ohbx_day_change_schedule).
-export([first_sunday_of_november/1,
	second_sunday_of_march/1,
        schedules_for_EDT/0]).

schedules_for_EDT() ->
	DLS_ABSENT_MONTHS = [1,2,12],
	DLS_MONTHS = [4,5,6,7,8,9,10],
	STATIC_MONTH_SCHEDULES = 
	lists:map(fun(M) -> {cron, {[0], [5], all, [M], all}} end, DLS_ABSENT_MONTHS) ++
	lists:map(fun(M) -> {cron, {[0], [4], all, [M], all}} end, DLS_MONTHS),
	MarchSchedules = lists:flatmap(fun march_edt_schedules/1, lists:seq(2017,2022)),
	NovSchedules = lists:flatmap(fun november_edt_schedules/1, lists:seq(2017,2022)),
	STATIC_MONTH_SCHEDULES ++ MarchSchedules ++ NovSchedules.

splitSchedules(Year, Month, SplitDay, BeforeOffset, AfterOffset, DaysInMonth) ->
	StartDays = lists:seq(1, SplitDay - 1),
	EndDays = lists:seq(SplitDay, DaysInMonth),
        MonthBeforeSchedule = lists:map(fun(Day) ->
	  {oneshot, {{Year, Month, Day}, {BeforeOffset,0,0}}}
	end,
	StartDays),
        MonthAfterSchedule = lists:map(fun(Day) ->
	  {oneshot, {{Year, Month, Day}, {AfterOffset,0,0}}}
	end,
	EndDays),
	MonthBeforeSchedule ++ MonthAfterSchedule.

november_edt_schedules(Year) ->
       splitSchedules(Year, 11, first_sunday_of_november(Year), 4, 5, 30).	

march_edt_schedules(Year) ->
       splitSchedules(Year, 3, second_sunday_of_march(Year), 5, 4, 31).	

first_sunday_of_november(Year) -> 
	YearMapping = dict:from_list([
          {2015, 1},
          {2016, 6},
          {2017, 5},
          {2018, 4},
          {2019, 3},
          {2020, 1},
          {2021, 7},
          {2022, 6}
	]),
	fetch_default(Year, YearMapping, 1).

second_sunday_of_march(Year) -> 
	YearMapping = dict:from_list([
          {2015, 8},
          {2016, 13},
          {2017, 12},
          {2018, 11},
          {2019, 10},
          {2020, 8},
	  {2021, 14},
	  {2022, 13}
	]),
	fetch_default(Year, YearMapping, 8).

fetch_default(Key, Dict, Default) ->
	case dict:find(Key, Dict) of
		{ok, Value} -> Value;
		_ -> Default
	end.
