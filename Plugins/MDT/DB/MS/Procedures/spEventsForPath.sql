IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spEventsForPath') 
  EXEC('CREATE PROCEDURE spEventsForPath AS')
GO

ALTER PROCEDURE spEventsForPath
AS
  DECLARE @Event_Date BIGINT
  select @Event_Date=min(Event_Date) from
      (
        select e.ID_Camera,MAX(Event_Date) as Event_Date from Zone z inner join Event e on e.ID_Event=z.ID_Event where z.ID_Path>0 group by e.ID_Camera
      ) a
  set @Event_Date=ISNULL(@Event_Date,DATEDIFF(SECOND,{d '1970-01-01'}, GETDATE())-86400*1000*60)
  select top 2048 e.ID_Event,e.ID_Camera,e.Event_Date,MIN(z.ID_Zone) as ZMin into #tmpEvent from Event e inner join Zone z on z.ID_Event=e.ID_Event
      where e.Event_Date>@Event_Date and z.ID_Path is null group by e.ID_Event,e.ID_Camera,e.Event_Date order by e.Event_Date
  select e.ID_Event,e.ID_Camera,e.Event_Date,DATEDIFF(MILLISECOND,MAX(e2.Event_Date),e.Event_Date) as MDiff into #tmpEvent2 from #tmpEvent e
      left join #tmpEvent e2 on e2.ID_Camera=e.ID_Camera and e2.Event_Date<e.Event_Date group by e.ID_Event,e.ID_Camera,e.Event_Date
  SELECT e.ID_Event,z.ID_Zone,z.ID_Zone as Zone2,z.Square_To/100 as ToY,z.Square_To%100 as PathX into #tmpEventZone from #tmpEvent2 e
      left join Zone z on z.ID_Event=e.ID_Event
  select ID_Event,ID_Zone,Zone2,ToY,PathX from #tmpEventZone order by ID_Event
  DROP TABLE #tmpEvent2
  DROP TABLE #tmpEvent
  drop table #tmpEventZone
GO
