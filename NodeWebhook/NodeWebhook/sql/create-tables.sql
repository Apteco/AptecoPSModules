-- sql/create-tables.sql
-- Zieltabellen im SQL Server anlegen.
-- Ausführen als einmalige Migration, z.B.:
--   sqlcmd -S localhost -d WebhookDB -i sql/create-tables.sql

-- ------------------------------------------------------------
-- Generische Fallback-Tabelle (alle nicht explizit gerouteten Endpunkte)
-- ------------------------------------------------------------
IF NOT EXISTS (
  SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.WebhookEvents') AND type = 'U'
)
BEGIN
  CREATE TABLE dbo.WebhookEvents (
    Id          BIGINT          NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Endpoint    NVARCHAR(100)   NOT NULL,
    Payload     NVARCHAR(MAX)   NOT NULL,
    Headers     NVARCHAR(MAX)   NULL,
    SourceIp    NVARCHAR(50)    NULL,
    ReceivedAt  DATETIME2(7)    NOT NULL,
    InsertedAt  DATETIME2(7)    NOT NULL DEFAULT SYSUTCDATETIME()
  );

  CREATE INDEX IX_WebhookEvents_Endpoint_ReceivedAt
    ON dbo.WebhookEvents (Endpoint, ReceivedAt DESC);

  PRINT 'Tabelle dbo.WebhookEvents erstellt.';
END
ELSE
  PRINT 'Tabelle dbo.WebhookEvents existiert bereits.';
GO

-- ------------------------------------------------------------
-- GitHub Events
-- ------------------------------------------------------------
IF NOT EXISTS (
  SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.GithubEvents') AND type = 'U'
)
BEGIN
  CREATE TABLE dbo.GithubEvents (
    Id          BIGINT          NOT NULL IDENTITY(1,1) PRIMARY KEY,
    EventType   NVARCHAR(100)   NULL,    -- x-github-event Header
    DeliveryId  NVARCHAR(100)   NULL,    -- x-github-delivery Header
    Repository  NVARCHAR(255)   NULL,
    Action      NVARCHAR(100)   NULL,
    Payload     NVARCHAR(MAX)   NOT NULL,
    SourceIp    NVARCHAR(50)    NULL,
    ReceivedAt  DATETIME2(7)    NOT NULL,
    InsertedAt  DATETIME2(7)    NOT NULL DEFAULT SYSUTCDATETIME()
  );

  CREATE INDEX IX_GithubEvents_EventType
    ON dbo.GithubEvents (EventType, ReceivedAt DESC);

  PRINT 'Tabelle dbo.GithubEvents erstellt.';
END
ELSE
  PRINT 'Tabelle dbo.GithubEvents existiert bereits.';
GO

-- ------------------------------------------------------------
-- Shopify Events
-- ------------------------------------------------------------
IF NOT EXISTS (
  SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.ShopifyEvents') AND type = 'U'
)
BEGIN
  CREATE TABLE dbo.ShopifyEvents (
    Id          BIGINT          NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Topic       NVARCHAR(200)   NULL,    -- x-shopify-topic Header
    ShopDomain  NVARCHAR(255)   NULL,
    OrderId     BIGINT          NULL,
    Payload     NVARCHAR(MAX)   NOT NULL,
    SourceIp    NVARCHAR(50)    NULL,
    ReceivedAt  DATETIME2(7)    NOT NULL,
    InsertedAt  DATETIME2(7)    NOT NULL DEFAULT SYSUTCDATETIME()
  );

  CREATE INDEX IX_ShopifyEvents_Topic
    ON dbo.ShopifyEvents (Topic, ReceivedAt DESC);

  CREATE INDEX IX_ShopifyEvents_ShopDomain
    ON dbo.ShopifyEvents (ShopDomain, ReceivedAt DESC);

  PRINT 'Tabelle dbo.ShopifyEvents erstellt.';
END
ELSE
  PRINT 'Tabelle dbo.ShopifyEvents existiert bereits.';
GO
