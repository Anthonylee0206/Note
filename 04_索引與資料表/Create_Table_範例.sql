DROP TABLE IF EXISTS user_currency
GO

DROP TABLE IF EXISTS user_currency_archive
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[user_currency](
	[user_id] [varchar](50) NOT NULL,
	[curr_id] [varchar](10) NOT NULL,
	[merchant_id] [varchar](10) NOT NULL,
 CONSTRAINT [PK_usercurrency] PRIMARY KEY CLUSTERED 
(
	[user_id] ASC,
	[curr_id] ASC,
	[merchant_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[user_currency_archive](
	[user_id] [varchar](50) NOT NULL,
	[curr_id] [varchar](10) NOT NULL,
	[merchant_id] [varchar](10) NOT NULL,
 CONSTRAINT [PK_usercurrency_archive] PRIMARY KEY CLUSTERED 
(
	[user_id] ASC,
	[curr_id] ASC,
	[merchant_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ek@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ek@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ek@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ek@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ek@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'KRW', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'USD', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDACHUN@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDACHUN@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDACHUN@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDACHUN@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDACHUN@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'KRW', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'USD', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idalong@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idandre@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idandre@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idandre@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idandre@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idandre@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idchandra@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idchandra@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idchandra@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idchandra@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idchandra@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddarwin@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddarwin@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddarwin@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddarwin@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddarwin@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddedy@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddedy@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddedy@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddedy@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddedy@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderigson@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin2@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin2@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin2@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin2@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin2@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idfaye@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idfaye@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idfaye@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idfaye@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idfaye@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idgrace@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idgrace@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idgrace@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idgrace@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idgrace@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'KRW', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'USD', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhenkie@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhenkie@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhenkie@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhenkie@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhenkie@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDJANE@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDJANE@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDJANE@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDJANE@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDJANE@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjimmy@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjimmy@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjimmy@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjimmy@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjimmy@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjoana@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjoana@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjoana@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjoana@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjoana@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'KRW', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'USD', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjovita@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjovita@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjovita@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjovita@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjovita@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjummy@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idkartika@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idkasio@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idkelvin@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idmichael@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idmira@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idmira@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idmira@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idmira@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idmira@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idramadhanu@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idricky@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idricky@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idricky@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idricky@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idricky@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'KRW', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'USD', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'IDR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsumiady@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsumiady@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsumiady@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsumiady@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsumiady@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsurya@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsurya@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsurya@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsurya@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsurya@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'IDR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDVIERI@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDVIERI@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDVIERI@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDVIERI@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDVIERI@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idwillis@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idwinda@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'idwindy@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'KRW', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'USD', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'IT001@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'IDR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'KRW', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'KRW', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'USD', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'pgadmin@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'pgadmin@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'pgadmin@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'pgadmin@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'pgadmin@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'IDR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH002', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH002', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH002', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH002', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH002', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'IDR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph005', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph005', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph005', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph005', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph005', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'IDR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'IDR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph009', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph009', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph009', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph009', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph009', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph010@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph010@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph010@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph010@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph010@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH011@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph015@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph015@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph015@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph015@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph015@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'IDR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'IDR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'KRW', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'USD', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH018@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH018@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH018@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH018@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH018@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH020@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH020@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH020@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH020@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH020@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH021@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH021@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH021@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH021@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH021@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH022@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH022@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH022@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH022@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH022@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH025@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH025@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH025@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH025@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH025@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH026@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH026@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH026@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH026@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH026@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH028@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH028@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH028@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH028@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH028@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH03@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'IDR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'IDR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'MYR', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'THB', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'VND', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH033@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH033@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH033@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH033@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH033@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH034@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH034@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH034@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH034@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH034@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH035@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH035@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH035@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH035@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH035@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph036@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH037@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH037@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH037@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH037@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH037@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH039@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH039@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH039@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH039@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH039@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH040@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH040@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH040@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH040@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH040@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH041@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH041@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH041@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH041@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH041@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph042@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph042@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph042@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph042@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph042@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH043@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH043@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH043@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH043@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH043@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH044@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH044@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH044@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH044@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH044@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH045@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH045@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH045@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH045@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH045@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH050@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH050@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH050@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH050@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH050@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH051@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH051@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH051@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH051@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH051@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH052@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH052@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH052@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH052@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH052@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH053@', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH053@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH053@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH053@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH053@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH060@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH060@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH060@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH060@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH060@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH061@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH061@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH061@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH061@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH061@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH062@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH062@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH062@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH062@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH062@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH063@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH063@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH063@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH063@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH063@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1101@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1101@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1101@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1101@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1101@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH11012@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH11012@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH11012@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH11012@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH11012@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1103@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1103@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1103@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1103@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1103@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2201@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2201@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2201@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2201@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2201@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2202@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2202@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2202@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2202@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2202@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2203@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2203@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2203@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2203@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2203@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2205@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2205@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2205@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2205@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2205@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2206@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2206@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2206@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2206@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2206@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2207@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2207@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2207@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2207@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2207@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2208@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2208@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2208@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2208@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2208@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2209@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2209@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2209@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2209@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2209@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2210@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2210@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2210@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2210@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2210@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2211@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2211@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2211@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2211@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2211@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2212@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2212@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2212@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2212@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2212@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2213@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2213@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2213@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2213@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2213@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2214@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2214@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2214@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2214@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2214@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2218@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2218@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2218@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2218@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2218@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2233@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2233@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2233@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2233@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2233@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2235@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2235@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2235@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2235@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2235@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2236@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2236@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2236@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2236@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2236@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'root', N'THB', N'146')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'root', N'THB', N'253')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'root', N'THB', N'342')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'root', N'VND', N'232')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'test@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'TH001@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'TH006@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI01@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI02@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI03@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI04@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI05@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI06@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI07@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI08@', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI09@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI10@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI11@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI12@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'thai13@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'tzz@-', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'tzz@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'tzz@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'tzz@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'tzz@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET01@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET02@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET03@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET04@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET05@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET06@', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET07@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET08@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'zw', N'CNY', N'')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'zw', N'CNY', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'zw', N'IDR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'zw', N'KRW', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'zw', N'MYR', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'zw', N'THB', N'-')
GO
INSERT [dbo].[user_currency] ([user_id], [curr_id], [merchant_id]) VALUES (N'zw', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ek@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ek@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ek@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ek@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'KRW', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'USD', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ictest003@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDACHUN@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDACHUN@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDACHUN@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDACHUN@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'KRW', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'USD', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idakhun', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idalong@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idandre@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idandre@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idandre@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idandre@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idchandra@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idchandra@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idchandra@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idchandra@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddarwin@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddarwin@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddarwin@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddarwin@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddedy@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddedy@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddedy@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iddedy@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderigson@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin2@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin2@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin2@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'iderwin2@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idfaye@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idfaye@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idfaye@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idfaye@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idgrace@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idgrace@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idgrace@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idgrace@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'KRW', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'USD', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhendra', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhenkie@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhenkie@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhenkie@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idhenkie@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDJANE@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDJANE@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDJANE@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDJANE@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjimmy@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjimmy@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjimmy@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjimmy@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjoana@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjoana@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjoana@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjoana@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'KRW', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'USD', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjonathan@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjovita@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjovita@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjovita@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjovita@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idjummy@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idkartika@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idkasio@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idkelvin@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idmichael@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idmira@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idmira@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idmira@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idmira@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idramadhanu@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idrichard@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idricky@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idricky@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idricky@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idricky@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'KRW', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'USD', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsiang', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'IDR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsonny@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsumiady@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsumiady@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsumiady@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsumiady@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsurya@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsurya@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsurya@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idsurya@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'IDR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idtommy@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDVIERI@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDVIERI@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDVIERI@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IDVIERI@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idwillis@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idwinda@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'idwindy@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'KRW', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'USD', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'irene@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'IT001@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'IDR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'KRW', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'it002@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'KRW', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'USD', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'kuochin@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'pgadmin@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'pgadmin@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'pgadmin@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'pgadmin@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'IDR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH001', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH002', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH002', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH002', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH002', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'IDR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph004', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph005', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph005', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph005', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph005', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'IDR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph006', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'IDR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph007', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph009', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph009', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph009', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph009', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph010@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph010@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph010@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph010@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH011@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph015@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph015@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph015@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph015@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'IDR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph016@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'IDR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'KRW', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'USD', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph017@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH018@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH018@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH018@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH018@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH020@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH020@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH020@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH020@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH021@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH021@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH021@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH021@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH022@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH022@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH022@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH022@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH025@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH025@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH025@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH025@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH026@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH026@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH026@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH026@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH028@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH028@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH028@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH028@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH03@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'IDR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH030@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'IDR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'MYR', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'THB', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'VND', N'')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH031@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH033@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH033@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH033@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH033@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH034@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH034@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH034@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH034@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH035@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH035@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH035@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH035@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'ph036@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH037@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH037@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH037@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH037@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH039@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH039@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH039@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH039@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH040@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH040@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH040@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH040@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH041@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH041@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH041@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH041@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph042@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph042@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph042@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'Ph042@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH043@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH043@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH043@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH043@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH044@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH044@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH044@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH044@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH045@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH045@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH045@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH045@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH050@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH050@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH050@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH050@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH051@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH051@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH051@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH051@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH052@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH052@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH052@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH052@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH053@', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH053@', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH053@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH053@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH060@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH060@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH060@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH060@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH061@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH061@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH061@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH061@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH062@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH062@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH062@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH062@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH063@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH063@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH063@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH063@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1101@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1101@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1101@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1101@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH11012@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH11012@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH11012@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH11012@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1103@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1103@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1103@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH1103@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2201@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2201@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2201@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2201@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2202@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2202@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2202@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2202@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2203@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2203@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2203@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2203@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2205@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2205@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2205@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2205@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2206@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2206@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2206@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2206@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2207@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2207@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2207@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2207@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2208@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2208@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2208@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2208@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2209@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2209@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2209@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2209@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2210@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2210@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2210@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2210@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2211@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2211@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2211@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2211@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2212@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2212@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2212@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2212@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2213@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2213@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2213@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2213@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2214@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2214@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2214@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2214@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2218@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2218@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2218@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2218@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2233@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2233@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2233@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2233@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2235@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2235@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2235@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2235@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2236@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2236@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2236@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'PH2236@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'root', N'THB', N'146')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'root', N'THB', N'253')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'root', N'THB', N'342')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'root', N'VND', N'232')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'TH001@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'TH006@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI01@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI02@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI03@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI04@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI05@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI06@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI07@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI08@', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI09@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI10@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI11@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'THAI12@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'thai13@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'tzz@-', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'tzz@-', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'tzz@-', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'tzz@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET01@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET02@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET03@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET04@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET05@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET06@', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET07@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'VIET08@-', N'VND', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'zw', N'IDR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'zw', N'KRW', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'zw', N'MYR', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'zw', N'THB', N'-')
GO
INSERT [dbo].[user_currency_archive] ([user_id], [curr_id], [merchant_id]) VALUES (N'zw', N'VND', N'-')
GO
ALTER TABLE [dbo].[user_currency] ADD  CONSTRAINT [DF_user_currency_user_id]  DEFAULT ('') FOR [user_id]
GO
ALTER TABLE [dbo].[user_currency] ADD  CONSTRAINT [DF_user_currency_curr_id]  DEFAULT ('') FOR [curr_id]
GO
ALTER TABLE [dbo].[user_currency] ADD  CONSTRAINT [DF_user_currency_merchant_id]  DEFAULT ('') FOR [merchant_id]
GO
