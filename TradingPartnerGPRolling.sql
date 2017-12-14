/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2008 (10.0.5500)
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2017
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

GO
/****** Object:  StoredProcedure [dbo].[amk_TradingPartner_GP_Rolling]    Script Date: 12/14/2017 10:00:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER Proc [dbo].[TradingPartner_GP_Rolling]
	@max INT
	, @quarterDate dateTIME
	, @tp_id nvarchar(4000) = NULL

AS
BEGIN
/*
==================================================================================================================
-- Revision Dt			Developers										Description
-- -----------  -----------------------------	-------------------------------------------------------------
-- 09/19/2017	Will Wendell, Nile Overstreet		Add Rollging Quarter Logic and @quarteDate, @tp_id parameters
==================================================================================================================
*/
/*
---------------------------------------TEST CODE--------------------------------

Exec  dbo.TradingPartner_GP_Rolling 100, '10/03/2017' , '134633,146694'

params
   Top X   (100,200,300)

   quater (1, 2, 3, 4)

   TradingPartner name   ( where TP ID is the binding value )

		SELECT  
			  [sTP_Name1]
			 ,[iTrading_Partner_ID]
			 ,[blnIsActive]
		FROM [AMARK_MTS_20170901].[dbo].[Trading_Partner]
		where [blnIsActive]=1
		order by 1

*/

			
	SELECT TOP(@max)     
			CASE Trade.sProfit_Center_CD 
				WHEN 'CompanyName1' THEN 'COMPANYNAME1'
				ELSE 'COMPANY2' 
			END AS Company,

			CONVERT(VARCHAR(2), Trade.dtTrade_DT, 101) + '/01/' + CONVERT(VARCHAR(4), Trade.dtTrade_DT, 102) AS TradeMonth,
			Trade.sCurrency_CD AS Currency, 
			Trade.decExchange_Rate AS ExchangeRate, 
			Profit_Center.sProfit_Center_Desc AS ProfitCenter,
			Trading_Partner.sTP_Name1 AS TradingPartner,
			Trade.sTrade_Paper_No AS Ticket#, 
			CONVERT(VARCHAR(10), Trade.dtTrade_DT, 101) AS TradeDate,                         
			Trade.sTrade_Type_CD AS Type, 
			Trade.sProduct_CD AS Product, 
			Trade.decTrade_Qty AS Quantity, 
			Trade.decTrade_Qty * Trade.decProduct_Ozconv AS Ounces, 
			Trade.decTrade_Unit_Price AS Price,                         
			Trade.decTrade_Ext_Price AS Ext_Price, 
			(Trade.decTrade_Ext_Price * Trade.decExchange_Rate) AS Ext_Price_USD , 
			Trade_PL.decPrem_Adj AS PremAdj, Trade.decTrade_Shipping_Charge AS ShippingCharge, 
			Trade.decTrade_Other_Charge AS OtherCharges, 
			Cast(Trade_PL.decPrem_Adj + (Trade.decTrade_Other_Charge * Trade.decExchange_Rate) AS decimal(19, 2)) AS GP_USD,  
			UPPER(REPLACE(trade.sTrade_Amark_Trader, 'M\','')) AS [A-MarkTrader] 
			, 
			-- Determines Quarter to Roll to
			(Select 
					Case
						When DATEPART(MM, @quarterDate) >= 7 AND DATEPART(MM, @quarterDate) < 10 Then 1
						When DATEPART(MM, @quarterDate) >= 10  Then 2
						When DATEPART(MM, @quarterDate) >= 1 AND DATEPART(MM, @quarterDate) < 4 Then 3
						When  DATEPART(MM, @quarterDate) >= 4 AND DATEPART(MM, @quarterDate) < 7 Then 4
					End AS RollingQuarter) 

				FROM Trade_PL 
					INNER JOIN Trade ON Trade_PL.iTrade_ID = Trade.iTrade_ID 
					INNER JOIN Trading_Partner ON Trade.iTrading_Partner_ID = Trading_Partner.iTrading_Partner_ID 
					INNER JOIN Profit_Center ON Trade.sProfit_Center_CD = Profit_Center.sProfit_Center_CD  
				WHERE 
				
				-- 1. @quarterDate is placed in its quarter range and the first of this quarter is subtracted from the Trade_Dt
				DateDiff(mm, 
						(Select 
							Case
								When DATEPART(MM, @quarterDate) >= 7 AND DATEPART(MM, @quarterDate) < 10 Then '7/1/' + Convert(varchar(12), DATEPART(yy, @quarterDate), 110)
								When DATEPART(MM, @quarterDate) >= 10  Then '10/1/'  + Convert(varchar(12), DATEPART(yy, @quarterDate), 110)
								When DATEPART(MM, @quarterDate) >= 1 AND DATEPART(MM, @quarterDate) < 4 Then '1/1/' + Convert(varchar(12), DATEPART(yy, @quarterDate), 110)
								When  DATEPART(MM, @quarterDate) >= 4 AND DATEPART(MM, @quarterDate) < 7 Then '4/1/' +Convert(varchar(12), DATEPART(yy, @quarterDate), 110)
							End ) , Trade.dtTrade_DT )  
				-- 2. This difference has to be greater or equal to the rolling index. 1st quarter rolling index index is 0
				--	because it's the base. 2nd quarter and onwards decrements by -3 because from the first quarter onwards we can roll forward from the first quarter.
							>=  (Select 
								Case
									When DATEPART(MM, @quarterDate) >= 7 AND DATEPART(MM, @quarterDate) < 10 Then 0
									When DATEPART(MM, @quarterDate) >= 10  Then -3
									When DATEPART(MM, @quarterDate) >= 1 AND DATEPART(MM, @quarterDate) < 4 Then -6
									When DATEPART(MM, @quarterDate) >= 4 AND DATEPART(MM, @quarterDate) < 7 Then -9
								End )
					AND
					-- 3. The Trade_Dt cannot go beyond the determined quarter. 
					DateDiff(mm, 
					(Select 
						Case
							When DATEPART(MM, @quarterDate) >= 7 AND DATEPART(MM, @quarterDate) < 10 Then '7/1/' + Convert(varchar(12), DATEPART(yy, @quarterDate), 110)
							When DATEPART(MM, @quarterDate) >= 10  Then '10/1/'  + Convert(varchar(12), DATEPART(yy, @quarterDate), 110)
							When DATEPART(MM, @quarterDate) >= 1 AND DATEPART(MM, @quarterDate) < 4 Then '1/1/' + Convert(varchar(12), DATEPART(yy, @quarterDate), 110)
							When  DATEPART(MM, @quarterDate) >= 4 AND DATEPART(MM, @quarterDate) < 7 Then '4/1/' +Convert(varchar(12), DATEPART(yy, @quarterDate), 110)
						End ) , Trade.dtTrade_DT
							)  <  3 
					-- 4. Specify by Trading Partner Ids 
					AND 
						(	@tp_id IS NOT NULL  AND						 						 
						Trading_Partner.iTrading_Partner_ID 
						IN (SELECT *  FROM SDF_SplitString (@tp_id , ','))
						)
						OR @tp_id IS NULL
					AND (Trade.blnTrade_Cancelled = 0)  
					AND (Trade.sTrade_Type_CD NOT IN ('LM','SM'))  
					ORDER BY Trade.iTrade_ID -- GP_USD DESC
END

