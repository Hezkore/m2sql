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
		nS.data = data
		
		If sqlite3_prepare_v2( db, data, -1, Varptr nS.stmt, Null ) = SQLITE_OK
		
			Return nS
		Else
			
			Print "Failed to Prepare Query - " + sqlite3_errmsg( db )
			sqlite3_finalize( nS.stmt )
		Endif
		
		Return Null
	End
	
	' Simple query
	Method Query:JsonObject( data:String )
		
		Local tmp := Prepare( data )
		
		If tmp Then
			
			Return tmp.Execute( True )
		Endif
		
		Return Null
	End
	
	Class Statement
		
		Field Parent:Database
		Field stmt:sqlite3_stmt Ptr
		Field result:JsonObject
		Field data:String
		
		Operator To:String()
			
			If Not result Then Return Null
			
			Return result.ToString()
		End
		
		Property Data:String()
			
			Return data
		End
		
		Property Result:JsonObject()
			
			Return result
		End
		
		Method New( parent:Database )
			
			Parent = parent
		End
		
		Method Reset()
			
			If stmt Then sqlite3_reset( stmt )
		End
		
		Method Discard()
			
			If stmt Then
				
				sqlite3_finalize( stmt )
				stmt = Null
			Endif
		End
		
		' Bind Int
		Method BindInt( index:Int, value:Int )
			
			If Not sqlite3_bind_int( stmt, index, value ) = SQLITE_OK Then
				
				Print "Failed to Bind Int - " + sqlite3_errmsg( Parent.db )
				sqlite3_finalize( stmt )
				stmt = Null
			Endif
		End
		
		' Bind Double
		Method BindDouble( index:Int, value:Double )
			
			If Not sqlite3_bind_double( stmt, index, value ) = SQLITE_OK Then
				
				Print "Failed to Bind Double - " + sqlite3_errmsg( Parent.db )
				sqlite3_finalize( stmt )
				stmt = Null
			Endif
		End
		
		' Bind Null
		Method BindNull( index:Int )
			
			If Not sqlite3_bind_null( stmt, index ) = SQLITE_OK Then
				
				Print "Failed to Bind Null - " + sqlite3_errmsg( Parent.db )
				sqlite3_finalize( stmt )
				stmt = Null
			Endif
		End
		
		' Bind Text
		Method BindText( index:Int, text:String )
			
			If Not sqlite3_bind_text( stmt, index, text, -1, SQLITE_TRANSIENT ) = SQLITE_OK Then
				
				Print "Failed to Bind Text - " + sqlite3_errmsg( Parent.db )
				sqlite3_finalize( stmt )
				stmt = Null
			Endif
		End
		
		' Execute the statment and return JSON data
		Method Execute:JsonObject( discard:Bool = False )
			
			result = New JsonObject
			Local colnum:Int = sqlite3_column_count( stmt ) ' Get Result Count
			Local rownum:Int = 0
			
			Repeat
				
				If stmt And sqlite3_step( stmt ) = SQLITE_ROW ' If there's a Row
					
					'Local print_string := "" ' Debug Output
					
					' Create New Row in Json
					Local row_id := String( rownum ) ' Get Row String ID
					result[row_id] = New JsonObject ' Create New Row from String ID
					
					Local newrow := result.GetObject( row_id ) ' Get New Row Ref
					
					' Generate Rows
					For Local i:Int = 0 Until colnum
						
						Local typeint := sqlite3_column_type( stmt, i ) ' Get Type of Entry
						Local colname := sqlite3_column_name( stmt, i ) ' Get Column Name
						
						Select typeint ' Determine the Correct Data Type
							
							Case 1 ' ADD INTEGER COLUMN
								
								Local colval:Int = sqlite3_column_int( stmt, i )
								newrow.SetNumber( colname, colval )
								
								'print_string += "INTEGER:" + colname + " " + colval + " | "
								
							Case 2 ' ADD FLOAT/REAL COLUMN
								
								Local colval:Double = sqlite3_column_double( stmt, i )
								newrow.SetNumber( colname, colval )
								
								'print_string += "REAL:" + colname + " " + colval + " | "
								
							Case 3 ' ADD STRING/TEXT COLUMN
								
								Local colval := sqlite3_column_text( stmt, i )
								newrow.SetString( colname, colval )
								
								'print_string += "TEXT:" + colname + " " + colval + " | "
								
							Case 4 ' ADD BLOB/ARRAY? COLUMN (Probably coming soon)
								
								'Local colval := sqlite3_column_blob( res, i )
								'print_string += "BLOB:" + colname + " " + colval + " | "
								
							Default ' NOT AN ACCEPTABLE TYPE FOR NOW
								
								Print "Unknown sqlite3 type - " + typeint
								'print_string += "UNKNOWN TYPE"
								
						End Select
					Next
					
					'Print print_string
					rownum += 1
				Else
					
					Exit ' - Exit Read Row Loop
				End
			Forever
			
			If discard Then
				
				Discard() ' Discard
			Else
			
				Reset() ' Reset
			Endif
			
			If rownum <= 0 Then Return Null
			
			Return result
		End Method
	End Class
End Class