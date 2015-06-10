-module(ohbx_day_change_schedule_test).
-compile(export_all).

-include_lib("eunit/include/eunit.hrl").

edt_schedule_test() ->
  FULL_SCHEDULE = ohbx_day_change_schedule:schedules_for_EDT(),
  ?assertEqual(lists:member({cron, {[0],[5],all,[1],all}},FULL_SCHEDULE),true),
  ?assertEqual(lists:member({cron, {[0],[5],all,[2],all}},FULL_SCHEDULE),true),
  ?assertEqual(lists:member({cron, {[0],[5],all,[12],all}},FULL_SCHEDULE),true),
  ?assertEqual(lists:member({cron, {[0],[4],all,[4],all}},FULL_SCHEDULE),true),
  ?assertEqual(lists:member({cron, {[0],[4],all,[5],all}},FULL_SCHEDULE),true),
  ?assertEqual(lists:member({cron, {[0],[4],all,[6],all}},FULL_SCHEDULE),true),
  ?assertEqual(lists:member({cron, {[0],[4],all,[7],all}},FULL_SCHEDULE),true),
  ?assertEqual(lists:member({cron, {[0],[4],all,[8],all}},FULL_SCHEDULE),true),
  ?assertEqual(lists:member({cron, {[0],[4],all,[9],all}},FULL_SCHEDULE),true),
  ?assertEqual(lists:member({cron, {[0],[4],all,[10],all}},FULL_SCHEDULE),true),
  ?assert(lists:member({oneshot, {{2017,3,11},{5,0,0}}},FULL_SCHEDULE)),
  ?assert(lists:member({oneshot, {{2017,3,12},{4,0,0}}},FULL_SCHEDULE)),
  ?assert(lists:member({oneshot, {{2016,11,5},{4,0,0}}},FULL_SCHEDULE)),
  ?assert(lists:member({oneshot, {{2016,11,6},{5,0,0}}},FULL_SCHEDULE)).

second_sunday_of_march_test() ->
  ?assertEqual(ohbx_day_change_schedule:second_sunday_of_march(2015), 8),
  ?assertEqual(ohbx_day_change_schedule:second_sunday_of_march(2016), 13),
  ?assertEqual(ohbx_day_change_schedule:second_sunday_of_march(2017),12),
  ?assertEqual(ohbx_day_change_schedule:second_sunday_of_march(2018),11),
  ?assertEqual(ohbx_day_change_schedule:second_sunday_of_march(2019),10),
  ?assertEqual(ohbx_day_change_schedule:second_sunday_of_march(2020),8).

first_sunday_of_november_test() ->
  ?assertEqual(ohbx_day_change_schedule:first_sunday_of_november(2015), 1),
  ?assertEqual(ohbx_day_change_schedule:first_sunday_of_november(2016), 6),
  ?assertEqual(ohbx_day_change_schedule:first_sunday_of_november(2017), 5),
  ?assertEqual(ohbx_day_change_schedule:first_sunday_of_november(2018), 4),
  ?assertEqual(ohbx_day_change_schedule:first_sunday_of_november(2019), 3),
  ?assertEqual(ohbx_day_change_schedule:first_sunday_of_november(2020), 1).
