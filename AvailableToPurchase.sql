/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2008 (10.0.5500)
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2017
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

GO
/****** Object:  StoredProcedure [dbo].[amk_GL_AvailableToPurchaseInv]    Script Date: 12/14/2017 9:37:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ========================================================================================
-- Author: Will Wendell 
-- Create date: 12/05/2017
-- Description: Gets available Inventory to buy
-- Used for SSRS. @porducts parameter turns into a drop down in report builder 2.0
-- ========================================================================================
ALTER PROC [dbo].[AvailableToPurchaseInv] 
				@depo varchar(10) = 'VEGAS'
				, @products varchar(max)
AS
BEGIN
		SELECT * FROM (
				SELECT	i.sDepository_CD,
							p.sCommodity_CD,
							i.sProduct_CD,
							p.sGoldStar_Metal_CD,
							p.sProduct_Desc1
						
							, i.decInv_Physical_Qty - SUM( t.decTrade_Product_Balance) AS ProductQty,
							  (i.decInv_Physical_Qty - SUM( t.decTrade_Product_Balance))*p.decProduct_Ozconv*1.00  AS  TotOz
							FROM 
								dbo.Inventory i
							 JOIN dbo.Product p ON i.sProduct_CD = p.sProduct_CD
							 FULL OUTER JOIN Trade t ON t.sProduct_CD = i.sProduct_CD
							WHERE i.decInv_Physical_Qty <> 0 
									AND p.sCommodity_CD <> 'CASH'
													AND i.sdepository_cd=@depo
													 AND p.decProduct_Ozconv > 0.0
													 AND t.sTrade_Type_Pay_Rec='PAY'
													 	AND blnTrade_Cancelled = 0
													 AND p.sProduct_CD IN (SELECT * FROM dbo.SDF_SplitString(@products, ','))
							GROUP BY 
							i.sDepository_CD,
							p.sCommodity_CD,
							i.sProduct_CD,
							p.sGoldStar_Metal_CD,
							p.sProduct_Desc1,
							 i.decInv_Physical_Qty,
							 p.decProduct_Ozconv 
							 ) final 
							 WHERE final.ProductQty > 0
END
