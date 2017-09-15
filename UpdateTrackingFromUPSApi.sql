ALTER PROC [dbo].[UpdateTrackingFromUPSApi] @ShipCollection ShippingStatusP3 readonly

AS
/*
---- Devs: Nile Overstreet, Will Wendell
---- Date: 9/11/2017
---- Description:
----	Inserts or Updates Tracking_Package table given a user defined table type, ShippingStatusP3. 
As of 09/152017, The proc is run in a console app that is integrated with UPS and USPS api

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
		VALUES (1, 'UPS', 'UPSEXP', '1Z2FV9999999999999', 253302, 442528, 'Transit')
		Exec [amk_UpdateTrackingFromUPSApi] @Tiger
		SELECT * FROM Tracking_PACKAGE_TB
		where [sCarrier_Tracking_No] = '1Z2FV9999999999999'
		select * from @Tiger
		SELECT * FROM Packages where [sCarrier_Tracking_No] = '1Z2FV9999999999999'
		
*/
BEGIN 

	DECLARE @index INT = 1
	DECLARE @size INT  = (select COUNT(id) from @ShipCollection)
	DECLARE @id INT

	WHILE @size >= @index
		BEGIN
			
			IF( 
			(SELECT sCarrier_Tracking_No FROM Tracking_PACKAGE_TB WHERE 
						(SELECT sCarrier_Tracking_No FROM @ShipCollection WHERE id = @index )
				Like  sCarrier_Tracking_No ) is null )

					BEGIN

						  INSERT INTO [dbo].[Packages]
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
					UPDATE Packages 
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
					WHERE Packages.[sCarrier_Tracking_No] = Ship.sCarrier_Tracking_No

				END

			SET @index += 1

		END
End
