USE [DB]
GO
/****** Object:  StoredProcedure [dbo].[Product_Update_V3] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[Product_Update_V3] 
		  @Id int
		, @Title nvarchar(50)
		, @Description nvarchar(500)
		, @BasePrice decimal(18,4)
		
		
		, @ModifiedBy nvarchar(128)
		, @ProductType int = 1
		, @MainImage nvarchar(255) = null
	    , @SecondaryImage nvarchar(255) = null
		, @Video nvarchar(255) = null
				
AS

/*
	DECLARE @Id int = 20;

	DECLARE @Title nvarchar(50) = 'Lolo'
	       , @Description nvarchar(100) = 'TttOrganic'
		   , @BasePrice decimal(18, 4) = 50
         
		   , @ModifiedBy nvarchar(128) = 'Frodo'
           , @ProductType int = 1
		   , @MainImage nvarchar(255) = 'https://images-na.ssl-images-amazon.com/images/I/81YH-pTg8VL._SY450_.jpg'
		   , @SecondaryImage nvarchar(255) = 'https://s-media-cache-ak0.pinimg.com/originals/dc/b5/6d/dcb56d48ed48c0d6f5032d478a20cda1.jpg'
		   , @Video nvarchar(255) = 'https://www.youtube.com/watch?v=4GuqJadv4r0';
		   
	EXEC dbo.Product_Update_V3
		     @Id
		   , @Title
		   , @Description
           , @BasePrice
           , @ModifiedBy
		   , @ProductType 
		   , @MainImage 
		   , @SecondaryImage 
		   , @Video 

		SELECT *
		FROM Product
		WHERE Id = @Id
*/

BEGIN
		DECLARE @ModifiedDate datetime2(7) = GETUTCDATE()
		UPDATE [dbo].[Product]
		   SET [Title] = @Title
			  ,[Description] = @Description
			  ,[BasePrice] = @BasePrice
			  ,[ModifiedBy] = @ModifiedBy
			  ,[ModifiedDate] = @ModifiedDate
			  , ProductType= @ProductType
			  , MainImage = @MainImage
			  , SecondaryImage = @SecondaryImage 
			  , Video = @Video 

		WHERE Id = @Id

 END

