--[[----------------------------------------------------------------------------
   
  Application Name:
  DatabaseAPI                                                                                                               
                                                                                              
  Summary:
  Introduction to the DataBase-API.
   
  Description:
  This sample includes a specific user interface for its application.
  The application itself creates a simple database and allows the user to insert
  data into and perform queries on it. 
  The user interface provides text fields to fill the fields of the database to insert
  new data and a possibility to send a query. It is possible to send a user-defined 
  or a predefined query.
  The results of the insertions and queries are printed on the page.
   
  How to run:
  Connect a web-browser to the AppEngine (localhost address "127.0.0.1") and you will 
  see the web-page of this sample.
  Fill in the data fields in the "Input Data" section and press "INSERT" to insert data
  into the database.
  Write a query in the text field in the "Query" section and press "EXECUTE" to perform a
  user defined query.
  To perform a predefined query, simply press the buttons in the "Query Templates" section.
  See the "Result" section for any output of the database. 
  
  The UI itself is created using the UI builder. It can be found by clicking the
  "database.msdd". In the drop-down menu at the upper right "Database" can be selected. 
  More information can be found in the tutorials. 
      
------------------------------------------------------------------------------]]

--Start of Global Scope---------------------------------------------------------
-- path for the database
local dbFileName = "private/demo.db"
-- path of the predefined database scheme
local dbSetupFileName = "resources/dbSetup.sql.txt"

-- initialize the database
local db              = nil
local insertStmt      = nil
local selectMaxIdStmt = nil

-- initialize global variables
local personFirstName  = ""
local personLastName   = ""
local personBirthYear  = ""
local personBirthMonth = ""
local personBirthDay   = ""
local sqlQuery         = ""
local nextPersonId     = 0

-- Serving functions for usage in GUI
Script.serveFunction("DatabaseAPI.setPersonFirstName",   "setPersonFirstName")
Script.serveFunction("DatabaseAPI.setPersonLastName",    "setPersonLastName")
Script.serveFunction("DatabaseAPI.setPersonBirthYear",   "setPersonBirthYear")
Script.serveFunction("DatabaseAPI.setPersonBirthMonth",  "setPersonBirthMonth")
Script.serveFunction("DatabaseAPI.setPersonBirthDay",    "setPersonBirthDay")
Script.serveFunction("DatabaseAPI.setSqlQuery",          "setSqlQuery")
Script.serveFunction("DatabaseAPI.getSqlQuery",          "getSqlQuery")
Script.serveFunction("DatabaseAPI.insert",               "insert")
Script.serveFunction("DatabaseAPI.exec",                 "exec")
Script.serveFunction("DatabaseAPI.execAllPersons",       "execAllPersons")
Script.serveFunction("DatabaseAPI.execAvgBirthYear",     "execAvgBirthYear")
Script.serveFunction("DatabaseAPI.execNumOfPersons",     "execNumOfPersons")
Script.serveFunction("DatabaseAPI.execClearTablePerson", "execClearTablePerson")

-- Serving events
local localOnResultEventName     = "OnResult"
local localOnSqlChangeEventName  = "OnSqlChange"
Script.serveEvent("DatabaseAPI.OnResult", localOnResultEventName)
Script.serveEvent("DatabaseAPI.OnSqlQueryChange", localOnSqlChangeEventName)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

--@printResult(text:String)
--triggers result-event
local function printResult(text)
  Script.notifyEvent(localOnResultEventName, text)
end

--@updateSql(sql:text)
--sets global sqlQuery and triggers sql-changed event
function updateSql(sql)
  sqlQuery = sql
  Script.notifyEvent(localOnSqlChangeEventName, sqlQuery)
end

--@setPersonFirstName(firstName:String)
function setPersonFirstName(firstName)
  personFirstName = firstName
end

--@setPersonLastName(lastName:String)
function setPersonLastName(lastName)
  personLastName = lastName
end

--@setPersonBirthYear(birthYear:String)
function setPersonBirthYear(birthYear)
  personBirthYear = birthYear
end

--@setPersonBirthMonth(birthMonth:String)
function setPersonBirthMonth(birthMonth)
  personBirthMonth = birthMonth
end

--@setPersonBirthDay(birthDay:String)
function setPersonBirthDay(birthDay)
  personBirthDay = birthDay
end

--@setSqlQuery(query:String)
function setSqlQuery(query)
  sqlQuery = query
end

--@getSqlQuery():String
function getSqlQuery()
  return sqlQuery
end

--@insert()
--inserts dataset into the database
function insert()
  if (insertStmt ~= nil) then
    insertStmt:bind(0, nextPersonId, {personFirstName, personLastName}, {personBirthYear, personBirthMonth, personBirthDay})
    if (insertStmt:step() == "DONE") then
      nextPersonId = nextPersonId + 1
      printResult("OK")
    else
      printResult("Coult not insert data: " .. insertStmt:getErrorMessage())
    end
    insertStmt:reset()
  else
    printResult("Could not insert data into DB because statement is not pre-compiled")
  end
end

--@exec()
--executes query
function exec()
  if (db ~= nil) then
    local tempStmt = db:prepare(sqlQuery)
    if (tempStmt ~= nil) then
      local stepResult = tempStmt:step()
      if (stepResult == "DONE") then
        printResult("OK")
      elseif (stepResult == "ROW") then
        local str = tempStmt:getColumnsAsString()
        while (tempStmt:step() == "ROW") do
          str = str .. "\r\n" .. tempStmt:getColumnsAsString()
        end
        printResult(str)
      elseif (stepResult == "ERROR") then
         printResult("Error: " .. tempStmt:getErrorMessage())
      end
    else
      printResult("Could not exec statement: " .. db:getErrorMessage())
    end
  else
    printResult("DB is not correctly set-up")
  end
end

--@execAllPersons()
function execAllPersons()
  updateSql("select * from Person")
  DatabaseAPI.exec()
end

--@execAvgBirthYear()
function execAvgBirthYear()
  updateSql("select avg(BirthYear) from Person")
  DatabaseAPI.exec()
end

--@execNumOfPersons()
function execNumOfPersons()
  updateSql("select count(*) from Person")
  DatabaseAPI.exec()
end

--@execClearTablePerson()
function execClearTablePerson()
  updateSql("delete from Person")
  DatabaseAPI.exec()
end

--@setupDb(bd:handle)
--executes initializing of database as stored in the setup-file
local function setupDb(db)
  local f = File.open(dbSetupFileName, "rb")
  if f ~= nil then
    local content = f:read()
    f:close()
    local couldExec = db:execute(content)
    if not couldExec then
      printResult("Could set-up DB: " .. db:getErrorMessage())
    end
  else
    printResult("Could not open DB set-up file")
  end
end

--@main()
local function main()
  db = Database.SQL.SQLite.create()
  db:openFile(dbFileName, "READ_WRITE_CREATE")
  setupDb(db)
  local nextPersonIdStatement = db:prepare("select case when max(Id) is null then 1 else max(Id) + 1 end from Person")
  assert(nextPersonIdStatement ~= nil)
  nextPersonIdStatement:step()
  nextPersonId = nextPersonIdStatement:getColumnInt(0)
  nextPersonIdStatement = nil
  insertStmt      = db:prepare("insert into Person values(?,?,?,?,?,?)")
  if (insertStmt == nil) then
    print("Error: " .. db:getErrorMessage())
  end
  selectMaxIdStmt = db:prepare("select max(Id) from Person")
  if (selectMaxIdStmt == nil) then
    print("Error: " .. db:getErrorMessage())
  end
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event 
Script.register("Engine.OnStarted", main)

--End of Function and Event Scope---------------------------------------------
