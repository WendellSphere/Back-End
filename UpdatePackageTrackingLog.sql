/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2008 (10.0.5500)
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2017
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/


GO
/****** Object:  StoredProcedure [dbo].[amk_UpdatePackageTrackingLog]    Script Date: 12/14/2017 10:19:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
=============================================================================================================
-- Developers: Nile Overstreet, Will Wendell
-- Date: 9/11/2017
-- Description:
--	Inserts or Updates Tracking_Package table given a user defined table type (ShippingStatus) while updateing [dtDeliver_DT] 
-- in Package table if the status is delivered. . 
-- As of 12/14/2017, The proc is run in a windows service that is integrated with UPS and USPS api
=============================================================================================================
*/
ALTER PROC [dbo].[UpdatePackageTrackingLog] 
	@ShipCollection ShippingStatus readonly
AS
/*
---------------------------- Test Code --------------------
		DECLARE @Tiger AS ShippingStatusP3
		INSERT INTO @Tiger
			( id, [sCarrier_CD]
						   ,[sCarrier_Medthod_CD]
						   ,[sCarrier_Tracking_No]
						   ,[sShipment_Request_ID]--[iShipment_Package_Hdr_ID]
						   ,[sPackage_ID]--[iShipment_Package_Dtl_ID]
						   , [StatusText]
						   )
		VALUES (1, 'UPS', 'UPSEXP', '1Z', 253302, 442528, 'Employee's''s check was not delivered333')
		Exec [UpdateTrackingFromUPSApi] @Tiger
		SELECT * FROM PackageTrackingLog
		where [sCarrier_Tracking_No] = '1Z'
		select * from @Tiger
		SELECT * FROM PackageTrackingLog where [sCarrier_Tracking_No] = '1Z2FV3983900595350'
		
*/
BEGIN 

	DECLARE @index INT = 1
	DECLARE @size INT  = (select COUNT(id) from @ShipCollection)
	DECLARE @id INT

	WHILE @size >= @index
		BEGIN
			
			IF( 
			(SELECT sCarrier_Tracking_No FROM PackageTrackingLog WHERE 
						(SELECT sCarrier_Tracking_No FROM @ShipCollection WHERE id = @index )
				Like  sCarrier_Tracking_No ) is null 
			)

				BEGIN

						INSERT INTO [dbo].PackageTrackingLog
							(
							[sCarrier_CD]
							,[sCarrier_Medthod_CD]
							,[sCarrier_Tracking_No]
							,[sShipment_Request_ID]
							,[sPackage_ID]
							,[blnPacking_Slip_Cancelled]
							,[StatusDate]
							,[StatusText]
							,[StatusLocation]
							,[dtTrans_Ship_DT])
					( SELECT 
								[sCarrier_CD]
							,[sCarrier_Medthod_CD]
							,[sCarrier_Tracking_No]
							,[sShipment_Request_ID]
							,[sPackage_ID]
							,[blnPacking_Slip_Cancelled]
							,[StatusDate]
							,[StatusText]
							,[StatusLocation]
							,[dtTrans_Ship_DT]
							FROM @ShipCollection AS Ship
							WHERE Ship.id = @index )
						 
			END
			ELSE
				BEGIN
					UPDATE PackageTrackingLog 
					SET 
								   [sCarrier_CD] =   Ship.sCarrier_CD 
								   ,[sCarrier_Medthod_CD] = Ship.sCarrier_Medthod_CD
								   ,[sShipment_Request_ID] = Ship.sShipment_Request_ID 
								   ,[sPackage_ID] = Ship.sPackage_ID 
								   ,[blnPacking_Slip_Cancelled] =  Ship.blnPacking_Slip_Cancelled 
								   ,[StatusDate]  =  Ship.StatusDate
								   ,[StatusText] = Ship.StatusText
								   ,[StatusLocation] = Ship.StatusLocation
								   ,[dtTrans_Ship_DT] = Ship.dtTrans_Ship_DT
					FROM @ShipCollection AS Ship
					WHERE PackageTrackingLog.[sCarrier_Tracking_No] = Ship.sCarrier_Tracking_No

				END

				UPDATE pack 
				SET pack.[dtDeliver_DT] = CAST(track.StatusDate AS Date)
				FROM Package pack
				INNER JOIN PackageTrackingLog track On track.sCarrier_Tracking_No = pack.sCarrier_Tracking_No
				WHERE track.StatusText LIKE 'DELIVERED%'
				AND pack.sCarrier_Tracking_No = track.sCarrier_Tracking_No
				AND track.sCarrier_Tracking_No = (SELECT s.sCarrier_Tracking_No FROM @ShipCollection s WHERE id = @index )
				AND pack.dtDeliver_DT IS  NULL

			SET @index += 1

		END
End


