USE db;

ALTER Function [dbo].[IsLastDayOfMonth](
	@Date datetime = null
)
Returns bit
/*
Select dbo.IsLastDayOfMonth('5/31/17')

select DATEADD(dd, 1, '5/31/17') 
select DATEPART(dd, DATEADD(dd, 1, GETDATE()) )

select DATEPART( mm, '5/31/17') 
*/
AS

Begin
		if @Date is null
			Begin
			if (DATEPART(dd, DATEADD(dd, 1, GETDATE()) ) = 1)
				Begin
					Return 1
				End

			End
		Else
			Begin
				if (DATEPART(dd, DATEADD(dd, 1, @Date ) ) = 1)
					Begin
						Return 1
					End

			End
	Return 0 
End

ALTER Function [dbo].[FindLastDayOfMonth](
	@Date dateTIME 
)
Returns datetime
/*---------------- TEST CODE-------------
Select dbo.IsLastDayOfMonth('5/30/17')

select dbo.FindLastDayOfMonth(NUUL)
*/
AS

BEGIN
		DECLARE @isLastDay BIT = 0
		IF @Date is null
			BEGIN
				SET @Date = GETDATE()
			END
		WHILE @isLastDay = 0
			BEGIN
				SET @isLastDay = dbo.IsLastDayOfMonth(@Date) 
				IF @isLastDay = 0
				BEGIN
					Set @Date = DATEADD(dd, 1, @Date)
				END
			END
		RETURN @Date
END
