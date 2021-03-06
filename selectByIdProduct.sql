USE [DB]
GO
/****** Object:  StoredProcedure [dbo].[Product_SelectById_V4]    Script Date: 6/9/2017 12:17:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Product_SelectById_V4]
	@Id INT

AS
/*******Test Code**********

		DECLARE @Id INT = 27

		EXECUTE [dbo].[Product_SelectById_V4]
		@Id

*/
BEGIN

	SELECT vp.Id
		  , vp.title
		  , vp.description
		  , vp.baseprice
		  , vp.createdby
		  , vp.createddate
		  , vp.modifiedby
		  , vp.modifieddate
		  , vp.producttype
		  , vp.[Main Product Image]
		  , vp.[Secondary Product Image]
		  , vp.[Main Product Video]
	FROM [dbo].[ViewProducts] AS vp
	INNER JOIN dbo.Product AS p	
			ON p.Id = vp.Id
			WHERE  p.IsDeleted = 0 
			AND vp.Id = @Id
  

END

