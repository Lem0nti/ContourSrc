INSERT INTO Config (Category, Name, Data) VALUES ('Main', 'TCP', 2110) ON CONFLICT DO NOTHING;

drop procedure if exists spAlarmByDayAndCamera;
drop procedure if exists spDeleteCamera;
drop procedure if exists spDropArch;
drop procedure if exists spGetFragment;
drop procedure if exists spIndexByDayAndCamera;
drop procedure if exists spInsertAlarm;
drop procedure if exists spInsertLog;
drop procedure if exists spInsertMotion;
drop procedure if exists spInsertSecondaryVideo;
drop procedure if exists spInsertVideo;
drop procedure if exists spMotionByDayAndCamera;
drop procedure if exists spUpdateVersion;