DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_alarm_camera') THEN
        ALTER TABLE IF EXISTS Alarm ADD CONSTRAINT FK_Alarm_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_fill_archive') THEN
        ALTER TABLE IF EXISTS Fill ADD CONSTRAINT FK_Fill_Archive FOREIGN KEY (ID_Archive) REFERENCES Archive (ID_Archive);
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_fill_camera') THEN
        ALTER TABLE IF EXISTS Fill ADD CONSTRAINT FK_Fill_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_motion_camera') THEN
        ALTER TABLE IF EXISTS Motion ADD CONSTRAINT FK_Motion_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_plugin_camera_camera') THEN
        ALTER TABLE IF EXISTS Plugin_Camera ADD CONSTRAINT FK_Plugin_Camera_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_plugin_camera_plugin') THEN
        ALTER TABLE IF EXISTS Plugin_Camera ADD CONSTRAINT FK_Plugin_Camera_Plugin FOREIGN KEY (ID_Plugin) REFERENCES Plugin (ID_Plugin);
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_plugin_param_plugin_camera') THEN
        ALTER TABLE IF EXISTS Plugin_Param ADD CONSTRAINT FK_Plugin_Param_Plugin_Camera FOREIGN KEY (ID_Plugin_Camera) REFERENCES Plugin_Camera (ID_Plugin_Camera);
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_schedule_camera') THEN
        ALTER TABLE IF EXISTS Schedule ADD CONSTRAINT FK_Schedule_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_secondaryvideo_archive') THEN
        ALTER TABLE IF EXISTS SecondaryVideo ADD CONSTRAINT FK_SecondaryVideo_Archive FOREIGN KEY (ID_Archive) REFERENCES Archive (ID_Archive);
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_secondaryvideo_camera') THEN
        ALTER TABLE IF EXISTS SecondaryVideo ADD CONSTRAINT FK_SecondaryVideo_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_video_archive') THEN
        ALTER TABLE IF EXISTS Video ADD CONSTRAINT FK_Video_Archive FOREIGN KEY (ID_Archive) REFERENCES Archive (ID_Archive);
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_video_camera') THEN
        ALTER TABLE IF EXISTS Video ADD CONSTRAINT FK_Video_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);
    END IF;
END;
$$;
