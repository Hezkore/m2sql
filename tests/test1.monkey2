' Searching the database

#Import "../m2sql"
Using m2sql..

#Import "assets/"

Function Main()
	
	' Load database
	Local DB := Database.Load( AssetsDir() + "chinook.db" )
	If Not DB Then Return
	
	' What to search for
	Local name := "For Those About To Rock (We Salute You)"
	
	
	' The simple way
	' This might break if "name" has special characters in it
	Local result := DB.Query( "SELECT *
	FROM tracks
	WHERE name = '" + name + "';" )
	
	If result Then Print result.ToJson()
	
	
	' The bind way
	' The ; is not needed here
	Local statement := DB.Prepare( "SELECT *
	FROM tracks
	WHERE name = ?" )
	
	If statement Then
		
		statement.BindText( 1, name )
		Print statement.Execute().ToJson()
	Endif
	
	' Cleanup
	DB.Close()
End