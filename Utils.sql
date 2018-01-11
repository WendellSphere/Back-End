/*
        Various SQL stored precedures and functions for utility purposes
        Authour: Will Wendell

*/
CREATE Proc [dbo].[CheckIfTablesAreEmtpy]
AS
BEGIN

	exec  sp_msforeachtable "IF EXISTS (select * from ?) begin print('? has rows') end else begin print('? NO rows'); end;"

END


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE PROC	[dbo].[EnableOrDisableConstrants]
	@Disable BIT = 0,
	@Enable	BIT = 0
AS
/*
TEST CODE
EXEC [amk_EnableOrDisableConstrants] 1
EXEC [amk_EnableOrDisableConstrants] 0,1
select * from sys.foreign_keys
*/
BEGIN
	IF(@Disable = 1)
		BEGIN
			-- Disable all constraints for database
			EXEC sp_msforeachtable "CREATE TABLE ? NOCHECK CONSTRAINT all" 

		END

	IF(@Enable = 1)	
		BEGIN
		-- Enable all constraints for database
			EXEC sp_msforeachtable "CREATE TABLE ? WITH CHECK CHECK CONSTRAINT all"  
		END

		print('SUCCESS')

END


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE Proc [dbo].[GetAllJobs]
AS
BEGIN
/*
TEST 
EXEC amk_GetAllJobs
*/
	SELECT 
		RS.ScheduleId AS ScheduleId_JobName
		, S.[SubscriptionID]
		  ,  CASE WHEN S.Description != ''
			 THEN S.Description 
			 Else  'N/A' 
			 END AS Description
     
	  FROM [ReportServer].[dbo].[Subscriptions] AS S
	  INNER JOIN [ReportServer].[dbo].ReportSchedule AS RS
	  ON RS.SubscriptionID = S.SubscriptionID
	  --WHERE S.Description  like '%WEEKLY%'
	   --WHERE S.Description  like '%AMCAD%'
	  --WHERE Description not like '%Quarterly%'
	  --exec [MSDB].[DBO].SP_START_JOB    @job_name = 'C27BF464-A7FA-486D-A505-9BFAA49C8139' ,@step_name= 'C27BF464-A7FA-486D-A505-9BFAA49C8139_step_1'
 

END

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE Proc [dbo].[GetCountOfRows]
AS
BEGIN
	/*
	TEST 
	EXEC amk_GetAllJobs
	*/
	SELECT
		  QUOTENAME(SCHEMA_NAME(sOBJ.schema_id)) + '.' + QUOTENAME(sOBJ.name) AS [TableName]
		  , SUM(sPTN.Rows) AS [RowCount]
	FROM 
		  sys.objects AS sOBJ
		  INNER JOIN sys.partitions AS sPTN
				ON sOBJ.object_id = sPTN.object_id
	WHERE
		  sOBJ.type = 'U'
		  AND sOBJ.is_ms_shipped = 0x0
		  AND index_id < 2 -- 0:Heap, 1:Clustered
	GROUP BY 
		  sOBJ.schema_id
		  , sOBJ.name
	ORDER BY [TableName]
END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


CREATE PROC [dbo].[amk_GetFKTree] (
  @TABLE VARCHAR(256) -- USE TWO PART NAME CONVENTION
, @LVL INT=0 -- DO NOT CHANGE
, @PARENTTABLE VARCHAR(256)='' -- DO NOT CHANGE
, @DEBUG bit = 1
)
AS
/*
exec dbo.amk_GetFKTree 'dbo.Trading_Partner'
*/
BEGIN
       SET NOCOUNT ON;
       DECLARE @DBG BIT;
       SET @DBG=@DEBUG;
       IF OBJECT_ID('TEMPDB..#TBL', 'U') IS NULL
             CREATE TABLE  #TBL  ([ID] INT IDENTITY, [TABLENAME] VARCHAR(256), [LVL] INT, [PARENTTABLE] VARCHAR(256));
             --DECLARE @TBL TABLE    (ID INT IDENTITY, TABLENAME VARCHAR(256), LVL INT, PARENTTABLE VARCHAR(256));

       DECLARE @CURS CURSOR;
       IF @LVL = 0
             INSERT INTO #TBL (TABLENAME, LVL, PARENTTABLE)
             SELECT @TABLE, @LVL, NULL;
       ELSE
             INSERT INTO #TBL (TABLENAME, LVL, PARENTTABLE)
             SELECT @TABLE, @LVL, @PARENTTABLE;
       IF @DBG=1    
             PRINT REPLICATE('----', @LVL) + 'LVL ' + CAST(@LVL AS VARCHAR(10)) + ' = ' + @TABLE;
       
       IF EXISTS (SELECT * FROM SYS.FOREIGN_KEYS WHERE REFERENCED_OBJECT_ID = OBJECT_ID(@TABLE))
	   BEGIN
			 SET @PARENTTABLE = @TABLE;
             SET @CURS = CURSOR FOR
             SELECT TABLENAME = OBJECT_SCHEMA_NAME(PARENT_OBJECT_ID)+'.'+OBJECT_NAME(PARENT_OBJECT_ID)
             FROM SYS.FOREIGN_KEYS 
             WHERE REFERENCED_OBJECT_ID = OBJECT_ID(@TABLE)
             AND PARENT_OBJECT_ID <> REFERENCED_OBJECT_ID; -- ADD THIS TO PREVENT SELF-REFERENCING WHICH CAN CREATE A INDEFINITIVE LOOP;

             OPEN @CURS;
             FETCH NEXT FROM @CURS INTO @TABLE;

             WHILE @@FETCH_STATUS = 0
             BEGIN --WHILE
                    SET @LVL = @LVL+1;
                    -- RECURSIVE CALL
                    EXEC DBO.[GetFKTree] @TABLE, @LVL, @PARENTTABLE, @DBG;
                    --SET @RESULT =  ( SELECT * FROM DBO.AMK_GETFKTREE (@TABLE, @LVL, @PARENTTABLE, @DBG))
                    SET @LVL = @LVL-1;
                    FETCH NEXT FROM @CURS INTO @TABLE;
             END --WHILE
             CLOSE @CURS;
             DEALLOCATE @CURS;
	   END
       IF @LVL = 0
             SELECT  ROW_NUMBER() OVER(ORDER BY LVL DESC) [INDEX], * FROM #TBL;
       RETURN;
END

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE PROC [dbo].[TruncateWithReferredTables]
@tableName varchar(250) = NULL
AS
/*
EXEC amk_TruncateAllTables '[dbo].[Ship_To_Address]'
*/
BEGIN

PRINT 'TABLE_NAME: ' + @tableName

DECLARE @TEMP TABLE ([INDEX] INT, ID INT, TABLENAME VARCHAR(256), LVL INT, PARENTTABLE VARCHAR(256))
DECLARE      @INDEX INT = 1

IF(@tableName IS NULL)
       BEGIN
             EXEC sp_MSforeachtable '
                         [dbo].[TruncateWithReferredTables] ''?''
                    '  
       END
ELSE
       BEGIN

             INSERT INTO @TEMP EXEC GetFKTree @tableName
             DECLARE @SIZE INT = (SELECT COUNT(*) FROM @TEMP) + 1
             PRINT 'SIZE: ' + CAST(@SIZE AS VARCHAR(15))
			 DECLARE @AddConstraintStatment VARCHAR(4000) = ''

             WHILE @INDEX < @SIZE       
             BEGIN
                    PRINT 'INDEX: ' + CAST(@INDEX AS VARCHAR(15))

                    DECLARE @Map Table([TBL_NAME] VARCHAR(250), [FK_NAME] VARCHAR(250), [COLUMN_NAME] VARCHAR(250), [IsFKHolder] BIT, [TBL_ID] INT, [FK_ID] INT, [COL_ID] INT) 
                    DECLARE @CurrentTable VARCHAR(250) = (SELECT TOP 1 TABLENAME FROM @TEMP WHERE [INDEX] = @INDEX)
                                 , @ParentTable VARCHAR(250) = (SELECT TOP 1 PARENTTABLE FROM @TEMP WHERE [INDEX] = @INDEX)
                                 , @DropConstraintStatment VARCHAR(4000) = ''
                                 , @TruncateStatment VARCHAR(4000) = ''

                    IF(@CurrentTable LIKE '%DBO%')
                           SET @CurrentTable = SUBSTRING(@CurrentTable, CHARINDEX('.', @CurrentTable, 0) + 1, LEN(@CurrentTable))

                    PRINT 'CURRENT TABLE: ' + @CurrentTable
                    PRINT 'PARENT TABLE: ' + @ParentTable

                    --GET RELATED FK NAMES
                    INSERT INTO @Map
                    SELECT * FROM GetFkMapping(@CurrentTable) FK

                    --SET SQL STATMENTS
                    SELECT @DropConstraintStatment += 'ALTER TABLE ' + M.TBL_NAME + ' DROP CONSTRAINT ' + M.FK_NAME + '; ' FROM @Map M WHERE M.IsFKHolder = 1 AND M.TBL_NAME LIKE @CurrentTable

                    SELECT @AddConstraintStatment += 'ALTER TABLE  ' +  M.TBL_NAME + ' ADD CONSTRAINT ' + M.FK_NAME + ' FOREIGN KEY(' 
                                                                      + M.COLUMN_NAME + ') ' 
                                                                      + ' REFERENCES '+ (SELECT TOP 1 _M.TBL_NAME FROM @Map _M WHERE _M.FK_ID = M.FK_ID AND _M.IsFKHolder = 0 ) + ' (' 
                                                                      + (SELECT TOP 1 _M.COLUMN_NAME FROM @Map _M WHERE _M.FK_ID = M.FK_ID AND _M.IsFKHolder = 0 ) 
                                                                      + ') ' 
                                                                      FROM @Map M WHERE M.IsFKHolder = 1
                    SET @TruncateStatment = 'TRUNCATE TABLE ' + @CurrentTable

                    
                    -- Empty Map Table Variable--
                    DELETE FROM   @Map

                    --EXECUTE GENERATED STATMENTS
                    
                    PRINT 'EXUCUTING ' + @DropConstraintStatment
                    EXEC sp_sqlexec @DropConstraintStatment

                    PRINT 'EXUCUTING ' + @TruncateStatment
                    EXEC sp_sqlexec @TruncateStatment                                                                          

                   

                    SET @INDEX += 1
             END

			 PRINT 'TRUNCATE COMPLETE'
			 PRINT 'EXUCUTING ' + @AddConstraintStatment
             EXEC sp_sqlexec @AddConstraintStatment
			 PRINT 'RESTORE COMPLETE'

       END
END


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE Function [dbo].[IsLastDayOfMonth](
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

BEGIN
		IF @Date is null
			BEGIN
			IF (DATEPART(dd, DATEADD(dd, 1, GETDATE()) ) = 1)
				BEGIN
					RETURN 1
				END

			END
		ELSE
			BEGIN
				IF (DATEPART(dd, DATEADD(dd, 1, @Date ) ) = 1)
					BEGIN
						RETURN 1
					END

			END
	RETURN 0 
END

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE Function [dbo].[FindLastDayOfMonth](
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

if @Date is null
	BEGIN
		SET @Date = GETDATE()
	END
SET @Date= DATEADD(MM, 1, @Date)
SET @Date= Convert(varchar(12), DATEPART(mm, @Date), 110) + '/1/' + Convert(varchar(12), DATEPART(yy, @Date), 110) + ' 23:59:59.99' 
SET @Date = DATEADD(DD, -1, @Date)

--DECLARE @isLastDay BIT = dbo.IsLastDayOfMonth(@Date) 

--WHILE @isLastDay = 0
--	BEGIN
--		SET @isLastDay = dbo.IsLastDayOfMonth(@Date) 
--		IF @isLastDay = 0
--		BEGIN
--			Set @Date = DATEADD(dd, 1, @Date) 
--		END
		
--	END
--	SET @Date = CONVERT(NVARCHAR(12), @Date, 110) + ' 23:59:59.99'
	RETURN @Date
END

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE  Function [dbo].[FindFirstDayOfMonth](
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

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SDF_SplitString]
(
    @sString nvarchar(MAX),
    @cDelimiter nchar(1)
)
RETURNS @tParts TABLE ( part nvarchar(2048) )
/* -------- Test Code ----------------
		DECLARE @example VARCHAR(120) = 'able,word,stuff'
		SELECT SUBSTRING(@example, 1, 1)
		SELECT *  FROM SDF_SplitString (@example , ',')
*/
AS
BEGIN
    IF @sString IS NULL RETURN

    DECLARE @iStart INT
	, @iPos INT

    IF SUBSTRING( @sString, 1, 1 ) = @cDelimiter 
    BEGIN
        SET @iStart = 2
        INSERT INTO @tParts
        VALUES( NULL )
    END
    ELSE 
		BEGIN
			SET @iStart = 1
		END

    WHILE 1=1
		BEGIN
			SET @iPos = CHARINDEX( @cDelimiter, @sString, @iStart )
			IF @iPos = 0
				SET @iPos = LEN( @sString )+1
			IF @iPos - @iStart > 0          
				INSERT INTO @tParts
				VALUES  ( SUBSTRING( @sString, @iStart, @iPos-@iStart ))
			ELSE
				INSERT INTO @tParts
				VALUES( NULL )
			SET @iStart = @iPos+1
			IF @iStart > LEN( @sString ) 
				BREAK
		END
    RETURN

END



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[GetFKMapping]
(
@tblName varchar(250)
)
RETURNS @RESULT TABLE ( [TBL_NAME] VARCHAR(250), [FK_NAME] VARCHAR(250), [COLUMN_NAME] VARCHAR(250), [IsFKHolder] BIT, [TBL_ID] INT, [FK_ID] INT, [COL_ID] INT )
/*
SELECT * FROM  dbo.amk_GetFKMapping( 'dbo.Trading_Partner_Contact')
*/
AS
BEGIN

IF(@tblName like '%dbo%')
	SET @tblName = SUBSTRING(@tblName, CHARINDEX('.', @tblName, 0) + 1, LEN(@tblName)) 

INSERT INTO @RESULT
SELECT DISTINCT
		 T.name				[TBL_NAME]
		,F.name				[FK_NAME]
		,C.name				[COLUMN_NAME]
		,CASE 
			WHEN SUB.parent_object_id = T.object_id
			THEN 1
			ELSE 0
		END AS				[IsFKHolder]
		,T.object_id		[TBL_ID]
		,F.object_id		[FK_ID]
		,C.column_id		[COL_ID]
FROM
(
	SELECT _FKC.*
	FROM sys.tables _T
	JOIN sys.foreign_keys _F ON _F.parent_object_id = _T.object_id
	JOIN sys.foreign_key_columns _FKC ON _FKC.constraint_object_id = _F.object_id
	WHERE _T.NAME = @tblName
) SUB

JOIN sys.tables T
	ON SUB.parent_object_id = T.object_id
	OR SUB.referenced_object_id = T.object_id
	

JOIN sys.foreign_keys F
	ON F.object_id = SUB.constraint_object_id


JOIN SYS.columns C
	ON 
		SUB.parent_column_id = C.column_id AND SUB.parent_object_id = C.object_id
 
 
 RETURN 

END
