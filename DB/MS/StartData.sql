IF NOT EXISTS(SELECT * FROM Config where Category='Main' and Name='TCP')
  INSERT INTO Config (Category, Name, Data) VALUES ('Main', 'TCP', 2110)
GO
