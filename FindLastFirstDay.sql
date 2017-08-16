USE db;

ALTER  Function [dbo].[FindFirstDayOfMonth](
	@Date dateTIME 
)
Returns datetime
/*---------------- TEST CODE-------------
Select dbo.IsLastDayOfMonth('5/31/17')

select dbo.FindFirstDayOfMonth(NUlL)
*/
AS

BEGIN
	if @Date is null
	Begin
		Set @Date = GETDATE()
	End
	
	Set @Date = Convert(varchar(12), DATEPART(mm, @Date), 110) + '/1/' + Convert(varchar(12), DATEPART(yy, @Date), 110) + ' 00:00:00' 

	RETURN  @Date
END

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

ALTER  Function [dbo].[FindFirstDayOfMonth](
	@Date dateTIME 
)
Returns datetime
/*---------------- TEST CODE-------------
Select dbo.IsLastDayOfMonth('5/30/17')

select dbo.FindFirstDayOfMonth(NUlL)
*/
AS

BEGIN
		SET @Date =  dbo.FindLastDayOfMonth(@Date)
		SET @Date =  DATEADD(DD, 1, @Date)
		SET @Date =  DATEADD(mm, -1, @Date)
		RETURN  @Date
END


ALTER Function [dbo].[FindLastDayOfMonth](
	@Date datetime 
)
Returns datetime
/*

select dbo.FindLastDayOfMonth(NULL)

DECLARE @D DATETIME = '12/03/2017'
SET @D = DATEADD(MM, 1, @D)
SET @D = Convert(varchar(12), DATEPART(mm, @D), 110) + '/1/' + Convert(varchar(12), DATEPART(yy, @D), 110) + ' 23:59:59.99' 
SET @D = DATEADD(DD, -1, @D)
SELECT @D
*/
AS

BEGIN
		IF @Date IS NULL
			BEGIN
				SET @Date = GETDATE()
			END
		SET @Date= DATEADD(MM, 1, @Date)
		SET @Date= Convert(varchar(12), DATEPART(mm, @Date), 110) 
			+ '/1/' + Convert(varchar(12), DATEPART(yy, @Date), 110) + ' 23:59:59.99' 
		SET @Date = DATEADD(DD, -1, @Date)

	RETURN @Date
END
