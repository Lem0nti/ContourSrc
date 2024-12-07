CREATE UNIQUE INDEX IF NOT EXISTS IX_Event_Camera ON Event (ID_Camera) INCLUDE (Event_Date);

CREATE UNIQUE INDEX IF NOT EXISTS IX_Event_Camera_Event_Date ON Event (ID_Camera,Event_Date) INCLUDE (ID_Event);

CREATE UNIQUE INDEX IF NOT EXISTS IX_Zone_Event ON Zone (ID_Event) INCLUDE (Square_From,Square_To);

CREATE UNIQUE INDEX IF NOT EXISTS IX_Zone_Path ON Zone (ID_Path) INCLUDE (ID_Zone,ID_Event);


