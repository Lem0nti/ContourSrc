DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_zone_event') THEN   
        ALTER TABLE IF EXISTS Zone ADD CONSTRAINT FK_Zone_Event FOREIGN KEY (ID_Event) REFERENCES Event (ID_Event);   
    END IF;   
END;   
$$;

DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_zone_path') THEN   
        ALTER TABLE IF EXISTS Zone ADD CONSTRAINT FK_Zone_Path FOREIGN KEY (ID_Path) REFERENCES Path (ID_Path);
    END IF;
END;
$$;

