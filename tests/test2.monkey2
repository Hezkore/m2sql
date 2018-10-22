' Creating a database

#Import "../m2sql"
Using m2sql..

Function Main()
	
	' Remove the database if it exists
	DeleteFile( AssetsDir() + "mydatabase.db" )
	
	' Load database ( create if it doesn't exist )
	Local DB := Database.Load( AssetsDir() + "mydatabase.db" )
	If Not DB Then Return
	
	' Create new 'users' table
	Local result := DB.Query( "CREATE TABLE users (
	 'id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
	 'name' TEXT,
	 'salt' TEXT,
	 'password' TEXT );" )
	
	' Add new users to the table
	result = DB.Query( "INSERT INTO users (
	 name,
	 salt,
	 password )
	VALUES (
	 'First User',
	 'Salty',
	 'MyPassword' );" )
	
	result = DB.Query( "INSERT INTO users (
	 name,
	 salt,
	 password )
	VALUES (
	 'Second User',
	 'Slatier',
	 'SomePassword' );" )
	
	' Print salt from a specific user
	result = DB.Query( "SELECT salt
	FROM users
	WHERE name = 'First User';" )
	
	If result Then Print result.ToJson()
	
	' Print all users
	result = DB.Query( "SELECT *
	FROM users;" )
	
	If result Then Print result.ToJson()
	
	' Cleanup
	DB.Close()
End