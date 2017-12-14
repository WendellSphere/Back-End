/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2008 (10.0.5500)
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2017
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

GO
/****** Object:  StoredProcedure [dbo].[amk_NewProductEmail]    Script Date: 12/14/2017 9:47:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ========================================================================================
-- Author: Will Wendell , Nile Overstreet
-- Create date: 12/05/2017
-- Description: Runs right after a new product is inserted, sends out an email
-- ========================================================================================
ALTER PROC [dbo].[NewProductEmail]
	@productCD varchar(20)
AS
BEGIN

			DECLARE @productDes VARCHAR(1000),
					@productOZ VARCHAR(10)
			SELECT 
				@productDes = ISNULL(I.sProduct_Desc1, ISNULL(I.sProduct_Desc2 , ' ')),
				@productOZ = CAST(I.decProduct_Ozconv AS VARCHAR(10))
			FROM Product I WHERE I.sProduct_CD = @productCD

		DECLARE @beginHTML VARCHAR(200) = '<!DOCTYPE html><html lang="en">',
				@intialCD VARCHAR(200) = '<div>%s</div></br>',
				@CD VARCHAR(200),
				@intialDes VARCHAR(200) = '<div>%s</div></br>',
				@Des VARCHAR(200),
				@intialOZ VARCHAR(200) = '<div>OZ: %s </div></br>',
				@OZ VARCHAR(200),
				@recievers VARCHAR(500) = 'a@aol.ocm',
				@bcc VARCHAR(500) = 'g@gmail.com',
				@subject VARCHAR(50);

			EXEC xp_sprintf @CD OUTPUT, @intialCD, @productCD
			EXEC xp_sprintf @Des OUTPUT, @intialDes, @productDes
			EXEC xp_sprintf @OZ OUTPUT, @intialOZ, @productOZ
			EXEC xp_sprintf @subject OUTPUT, 'New Product Code Created %s', @productCD


			DECLARE	@body VARCHAR(1000) = @beginHTML + @CD + @Des + @OZ;
			 

			EXEC msdb.dbo.sp_send_dbmail @recipients = @recievers,
										@blind_copy_recipients = @bcc,
										@profile_name = NULL,
										@subject = @subject,
										@body = @body,
										@body_format = 'HTML'

END
