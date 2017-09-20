USE [DB]

ALTER FUNCTION [dbo].[SDF_SplitString]
(
    @sString nvarchar(MAX),
    @cDelimiter nchar(1)
)
RETURNS @tParts TABLE ( part nvarchar(2048) )
/* -------- Test Code ----------------
		DECLARE @example VARCHAR(120) = 'able,word,stuff'
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
