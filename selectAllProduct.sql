USE [DB]
GO
/****** Object:  StoredProcedure [dbo].[Product_SelectAll_V4]    Script Date: 6/9/2017 12:20:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Product_SelectAll_V4]
			@IsDeleted int = 0
AS
/**********Test Code************  
	DECLARE @IsDeleted int = 0

	EXEC dbo.Product_SelectAll_V4 @IsDeleted
*/
BEGIN

		SELECT 
		p.[Id]
      ,p.[title]
      ,p.[description]
      ,p.[baseprice]
      ,p.[createdby]
      ,p.[createddate]
      ,p.[modifiedby]
      ,p.[modifieddate]
      ,p.[producttype]
      ,vp.[Main Product Image]
      ,vp.[Secondary Product Image]
      ,vp.[Main Product Video]
	  , p.IsDeleted
		FROM [dbo].[ViewProducts] AS vp
		INNER JOIN dbo.Product AS p	
		ON p.Id = vp.Id
		WHERE  p.IsDeleted = @IsDeleted 

END

