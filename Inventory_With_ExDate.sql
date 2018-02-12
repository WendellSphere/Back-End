-- ===================================================================================================
-- Author: Will Wendell 
-- Create date: 01/17/2018
-- Description:	Gets inventory and calcuates the expieration dates per entry and the entry's quantitity 
-- =====================================================================================================
ALTER PROC [dbo].[Inventory_With_ExDate]
@depo VARCHAR(15)
AS
BEGIN

	--** Inventory Comming in **--
	DECLARE @dataSetPR TABLE (
	 Id INT
	 , sDepository_CD VARCHAR(15)
	 , sCommodity_CD VARCHAR(4)
	 ,  sProduct_CD VARCHAR(15)
	 , sGoldStar_Metal_CD VARCHAR (20)
	 , sProduct_Desc1 VARCHAR (100)
	 , ProductQty decimal (15,5)
	 , decProduct_Ozconv decimal (15,5)
	 , TotOz	decimal (15,5)
	 , sTrans_Type_CD  VARCHAR(15)
	 , DateEntered DATETIME
	 , ExperationDate DATETIME
	 )

	--** Inventory leaving **--	
	DECLARE @dataSetPD TABLE (Id INT
							, [Level] INT
							, sProduct_CD VARCHAR(15)
							, [ProductQty2] DECIMAL(15,5)
							, [DateEntered] DATETIME)

	INSERT INTO @dataSetPR
	SELECT 	  
			ROW_NUMBER() OVER(ORDER BY tr.sProduct_CD, t.dtTrade_DT ASC) [Id]
			 , D.sDepository_CD
			, P.sCommodity_CD
			, tr.sProduct_CD
			, P.sGoldStar_Metal_CD
			, P.sProduct_Desc1
			, tr.decTrans_Qty	[ProductQty]
			, P.decProduct_Ozconv
			, tr.decTrans_Qty * p.decProduct_Ozconv * 1.00  AS  [TotOz]
			,  tr.sTrans_Type_CD 
			, t.dtTrade_DT							[DateEntered]
			, DATEADD(DD, 22, t.dtTrade_DT)			[ExperationDate]
	FROM Trade t
	JOIN Depository d ON d.sDepository_CD = t.sDepository_CD
	JOIN Product p ON p.sProduct_CD = t.sProduct_CD
	JOIN Transactions tr ON tr.iTrade_ID = t.iTrade_ID
	JOIN Trading_Partner tp ON tp.iTrading_Partner_ID = t.iTrading_Partner_ID
	WHERE 
	GETDATE() < DATEADD(DD, 22, t.dtTrade_DT)
	AND t.blnTrade_Cancelled = 0 
	AND tr.sTrans_Type_CD = 'PR' 
	AND D.sDepository_CD =  @depo  

	INSERT INTO @dataSetPD 
	SELECT 	  
			ROW_NUMBER() OVER(ORDER BY tr.sProduct_CD, t.dtTrade_DT ASC) [Id]
			, ROW_NUMBER() OVER(PARTITION BY tr.sProduct_CD ORDER BY t.dtTrade_DT) [Level]
			, P.sProduct_CD
			, TR.decTrans_Qty [ProductQty]
			, t.dtTrade_DT		[DateEntered]
	FROM Trade t
	JOIN Depository d ON d.sDepository_CD = t.sDepository_CD
	JOIN Product p ON p.sProduct_CD = t.sProduct_CD
	JOIN Transactions tr ON tr.iTrade_ID = t.iTrade_ID
	JOIN Trading_Partner tp ON tp.iTrading_Partner_ID = t.iTrading_Partner_ID
	WHERE 
	GETDATE() < DATEADD(DD, 22, t.dtTrade_DT)
	AND t.blnTrade_Cancelled = 0 
	AND tr.sTrans_Type_CD IN ( 'PD')
	AND D.sDepository_CD =  @depo
	ORDER BY  Id ASC 

	/* --** Test Code **-
	SELECT * FROM @dataSetPR 
	SELECT top 30 * FROM @dataSetPD ORDER BY sProduct_CD , DateEntered ASC
	SELECT top 50 * FROM @dataSetPR ORDER BY sProduct_CD , DateEntered ASC
	*/

	DECLARE @row INT = 1
	, @level INT = 0
	, @size INT = (SELECT COUNT(*) FROM @dataSetPR)
	, @sizePD INT =  0 
	, @productCD VARCHAR(15) = ''
	, @TotalIn INT
	, @LevelIndex INT = 1
	
	WHILE @row < @size

	BEGIN 

		(SELECT @productCD = PD.sProduct_CD
				,@sizePD = COUNT(PD.sProduct_CD)
					 FROM @dataSetPD PD
					 JOIN @dataSetPR PR
						ON PR.sProduct_CD = PD.sProduct_CD
					 WHERE PR.Id = @row
					AND PD.DateEntered >= PR.DateEntered
					 GROUP BY PD.sProduct_CD)

		--** @levelIndex is used **--
		--** because @level will not always start at the same place and may be bigger than @sizePd **--
		IF( @productCD != '' )
		 BEGIN
			 WHILE  @LevelIndex  <= @sizePD 
				BEGIN
					
						IF @level = 0 
						BEGIN 
						
							SELECT top 1  @level = PD.[Level]
							FROM @dataSetPR PR
							JOIN @dataSetPD pD
							ON PR.sProduct_CD = PD.sProduct_CD
							WHERE PR.Id = @row
							AND PD.DateEntered >= PR.DateEntered
							ORDER BY PD.DateEntered ASC
						
						END

						SELECT TOP 1 @TotalIn = PR.ProductQty 
						FROM @dataSetPR PR
						WHERE PR.Id = @row
					
						--** Basically subtract PD's from PR's based on DateEntered **--
						UPDATE @dataSetPR 
						SET ProductQty =  CASE WHEN ProductQty >=  (ProductQty2 * -1)
												THEN ProductQty + ProductQty2 
												ELSE 0
										  END
						  , TotOz	=	  CASE WHEN ProductQty >=  (ProductQty2 * -1)	
											   THEN (ProductQty + ProductQty2 ) * PR.decProduct_Ozconv * 1.00
											   ELSE 0
										  END
						FROM @dataSetPD PD
						JOIN @dataSetPR PR
						ON PR.sProduct_CD = PD.sProduct_CD
						WHERE 
						 PD.[Level] = @level
						 AND PR.Id = @row
						AND PD.DateEntered >= PR.DateEntered

						--** To account the offset on leaving products **--
						UPDATE @dataSetPD 
						SET ProductQty2 = CASE WHEN ProductQty2 +  @TotalIn <= -1 
												THEN ProductQty2 + @TotalIn
												ELSE 0
												END
						FROM @dataSetPR PR
						JOIN @dataSetPD PD
						ON PR.sProduct_CD = PD.sProduct_CD
						WHERE PD.[Level] = @level
						AND PR.Id = @row
						AND PD.DateEntered >= PR.DateEntered

						SET @level += 1
						SET @LevelIndex  += 1
						
				END

				SET @level = 0
				SET @LevelIndex = 1

		 END

		 SET @productCD = ''
		 SET @row += 1

	END

	SELECT * 
	FROM @dataSetPR D
	WHERE D.ProductQty > 0
	ORDER BY 
	D.ExperationDate ASC
