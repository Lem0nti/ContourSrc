CREATE UNIQUE INDEX IF NOT EXISTS IX_Config ON Config (Category,Name);

CREATE INDEX IF NOT EXISTS IX_Video_ID_Camera_SEnd ON Video (ID_Camera,SEnd) INCLUDE (ID_Archive,SBegin);

CREATE UNIQUE INDEX IF NOT EXISTS IX_Plugin_Camera ON Plugin_Camera (ID_Plugin,ID_Camera);