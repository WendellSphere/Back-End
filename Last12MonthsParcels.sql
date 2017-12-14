/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2008 (10.0.5500)
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2017
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

GO
/****** Object:  StoredProcedure [dbo].[amk_TotalParcelsFromToByTradingPartnerID]    Script Date: 12/14/2017 8:20:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ====================================================
-- Author: Will Wendell 
-- Create date: 12/13/2017
-- Description:	Retrieves Parcels sent out to our
--		specified Trading Partenr and to their  customers for 
--		the past 12 months
-- ======================================================
ALTER PROC [dbo].[TotalParcelsFromToByTradingPartnerID]
			@iTrading_Partner_ID	INT

AS
/*---------------- Test Code -------------------------------------

	EXEC [dbo].[TotalParcelsFromToByTradingPartnerID]  500483    

*/ 
BEGIN	

	DECLARE @result  TABLE ( Comapny Varchar(50) , [Month] VARCHAR(30),  TotalParcels INT )
	DECLARE @i INT = 0	
	DECLARE @start DATE = dbo.FindFirstDayOfMonth( DATEADD( MM, -1, GETDATE() ) )
	DECLARE @end DATE = DBO.FindLastDayOfMonth(@start)
	DECLARE @name VARCHAR (50)
	DECLARE @name2 varchar (50)

 	;WITH #names AS ( SELECT DISTINCT sTrans_Ship_From_Name1 
					        
					  FROM Transactions AS t 

					  LEFT OUTER JOIN Trading_Partner AS tp 
					  ON t.iTrading_Partner_ID = tp.iTrading_Partner_ID

					  LEFT OUTER JOIN
					  Trans_Shipping_Address AS tsa 
					  ON t.iTrans_Shipping_Address_ID = tsa.iTrans_Shipping_Address_ID

					  WHERE tp.iTrading_Partner_ID = @iTrading_Partner_ID
					  AND sTrans_Ship_From_Name1  NOT LIKE 'ComapanyName' 
					  AND sTrans_Ship_From_Name1 IS NOT NULL
		 )

	SELECT TOP 1 @name = sTrans_Ship_From_Name1 
				, @name2 = (SELECT TOP 1 sTrans_Ship_From_Name1  
							FROM #names 
							WHERE sTrans_Ship_From_Name1 NOT LIKE B.sTrans_Ship_From_Name1)  
	FROM #names AS B

WHILE(  @i < 12 )
	BEGIN
			INSERT INTO  @result

			SELECT DISTINCT 
			'To: ' + TSA.[sTrans_Ship_To_Name1]  AS [Comapny]
			, DATENAME(MM, @start) + ' ' + CAST(YEAR(@start) AS VARCHAR(4)) AS [Month]
			, COUNT( TSA.[sTrans_Ship_To_Name1] ) AS TotalParcels
			FROM Transactions AS t 

			LEFT OUTER JOIN Trading_Partner AS tp 
			ON t.iTrading_Partner_ID = tp.iTrading_Partner_ID

			LEFT OUTER JOIN
            Trans_Shipping_Address AS tsa ON t.iTrans_Shipping_Address_ID = tsa.iTrans_Shipping_Address_ID
		
			WHERE tp.iTrading_Partner_ID = @iTrading_Partner_ID
			AND (TSA.[sTrans_Ship_To_Name1] LIKE @name OR TSA.[sTrans_Ship_To_Name1] LIKE @name2)
			AND TSA.[sTrans_Ship_From_Name1] LIKE 'ComapanyName'
			and sTrans_Ship_To_Address_Type_Desc not like 'drop ship'
			AND T.dtTrans_Ship_DT BETWEEN @start AND @end

			GROUP BY  TSA.[sTrans_Ship_To_Name1]    


			UNION


			SELECT 
			'To: Other Customers'  AS [Comapny]
			, DATENAME(MM, @start) + ' ' + CAST(YEAR(@start) AS VARCHAR(4)) AS [Month]
			, count( TSA.[sTrans_Ship_To_Name1] ) AS TotalParcels
			FROM Transactions AS T

			LEFT OUTER JOIN Trading_Partner AS tp 
			ON t.iTrading_Partner_ID = tp.iTrading_Partner_ID

			LEFT OUTER JOIN
			Trans_Shipping_Address AS tsa ON t.iTrans_Shipping_Address_ID = tsa.iTrans_Shipping_Address_ID
		
			WHERE tp.iTrading_Partner_ID = @iTrading_Partner_ID
			AND (TSA.[sTrans_Ship_From_Name1]  LIKE @name OR TSA.[sTrans_Ship_From_Name1]  LIKE @name2)
			AND sTrans_Ship_To_Address_Type_Desc   LIKE 'drop ship'
			AND T.dtTrans_Ship_DT BETWEEN @start AND @end
		

			SET @start =  DATEADD(MM, -1, @start)
		    SET @end = DBO.FindLastDayOfMonth(@start)
		    SET @i = @i + 1

	END

		SELECT * FROM @result as r
		ORDER BY CAST(r.Month  AS DATE) DESC

END

