' Original code by scurty
' http://monkeycoder.co.nz/forums/topic/wip-database-lib/
' Updated by Hezkore

Namespace m2sql

#Import "<std>"
#Import "<sqlite>"

Using sqlite..
Using std..

Extern
	
	Function SQLITE_STATIC:Void( Void Ptr )
	Function SQLITE_TRANSIENT :Void( Void Ptr )
Public

Class Database
	
	Field db:sqlite3 Ptr
	
	Field Path:String
	
	' If a database exists, load it, otherwise, create it
	Function Load:Database( path:String )
		
		Local nDB := New Database
		nDB.Path = path
		
		If Not sqlite3_open( nDB.Path, Varptr nDB.db ) = SQLITE_OK
			
			Print "Failed to Open Database - " + sqlite3_errmsg( nDB.db )
			nDB.Close()
		Endif
		
		Return nDB
	End
	
	' Closes the database
	Method Close()
		
		sqlite3_close( db )
	End
	
	' Prepare a statement
	Method Prepare:Statement( data:String )
		
		Local nS := New Statement( Self )
		
		If sqlite3_prepare_v2( db, data, -1, Varptr nS.res, Null ) = SQLITE_OK
		
			Return nS
		Else
			
			Print "Failed to Prepare Query - " + sqlite3_errmsg( db )
			Close() ' Close sql file
		Endif
		
		Return Null
	End
	
	' Simple query
	Method Query:JsonObject( data:String )
		
		Local tmp := Prepare( data )
		
		If tmp Then
			
			Return tmp.Execute()
		Endif
		
		Return Null
	End
	
	Class Statement
		
		Field Parent:Database
		Field res:sqlite3_stmt Ptr
		
		Method New( parent:Database )
			
			Parent = parent
		End
		
		' Bind int
		Method BindInt( index:Int, value:Int )
			
			If Not sqlite3_bind_int( res, index, value ) = SQLITE_OK Then
				
				Print "Failed to Bind Int - " + sqlite3_errmsg( Parent.db )
			Endif
		End
		
		' Bind double
		Method BindDouble( index:Int, value:Double )
			
			If Not sqlite3_bind_double( res, index, value ) = SQLITE_OK Then
				
				Print "Failed to Bind Double - " + sqlite3_errmsg( Parent.db )
			Endif
		End
		
		' Bind Null
		Method BindNull( index:Int )
			
			If Not sqlite3_bind_null( res, index ) = SQLITE_OK Then
				
				Print "Failed to Bind Null - " + sqlite3_errmsg( Parent.db )
			Endif
		End
		
		' Bind Text
		Method BindText( index:Int, text:String )
			
			If Not sqlite3_bind_text( res, index, text, -1, SQLITE_TRANSIENT ) = SQLITE_OK Then
				
				Print "Failed to Bind Text - " + sqlite3_errmsg( Parent.db )
			Endif
		End
		
		' Execute the statment and return JSON data
		Method Execute:JsonObject()
			
			Local rowsobj := New JsonObject
			Local colnum:Int = sqlite3_column_count( res ) ' Get Result Count
			Local rownum:Int = 0
			
			Repeat
				
				If sqlite3_step( res ) = SQLITE_ROW ' If there's a Row
					
					'Local print_string := "" ' Debug Output
					
					' Create New Row in Json
					Local row_id := Cast<String>(rownum) ' Get Row String ID
					rowsobj[row_id] = New JsonObject ' Create New Row from String ID
					
					Local newrow := rowsobj.GetObject(row_id) ' Get New Row Ref
					
					' Generate Rows
					For Local i:Int = 0 Until colnum
						
						Local typeint := sqlite3_column_type( res, i ) ' Get Type of Entry
						Local colname := sqlite3_column_name( res, i ) ' Get Column Name
						
						Select typeint ' Determine the Correct Data Type
							
						Case 1 ' ADD INTEGER COLUMN
							
							Local colval:Int = sqlite3_column_int( res, i )
							newrow.SetNumber(colname, colval)
							
							'print_string += "INTEGER:" + colname + " " + colval + " | "
							
						Case 2 ' ADD FLOAT/REAL COLUMN
							
							Local colval:Double = sqlite3_column_double( res, i )
							newrow.SetNumber(colname, colval)
							
							'print_string += "REAL:" + colname + " " + colval + " | "
							
						Case 3 ' ADD STRING/TEXT COLUMN
							
							Local colval := sqlite3_column_text( res, i )
							newrow.SetString(colname, colval)
							
							'print_string += "TEXT:" + colname + " " + colval + " | "
							
						Case 4 ' ADD BLOB/ARRAY? COLUMN (Probably coming soon)
							
							'Local colval := sqlite3_column_blob( res, i )
							'print_string += "BLOB:" + colname + " " + colval + " | "
							
						Default ' NOT AN ACCEPTABLE TYPE FOR NOW
							
							'print_string += "UNKNOWN TYPE"
							
						End Select
						
					Next
					
					'Print print_string
					rownum += 1
				Else
					
					Exit ' - Exit Read Row Loop
				End
			Forever
			
			sqlite3_finalize( res ) ' Clean up stmt?
			
			Return rowsobj
		End
	End
End