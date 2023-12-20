
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
Script.serveFunction("DatabaseAPI_SQLite.setPersonFirstName",   "setPersonFirstName")
Script.serveFunction("DatabaseAPI_SQLite.setPersonLastName",    "setPersonLastName")
Script.serveFunction("DatabaseAPI_SQLite.setPersonBirthYear",   "setPersonBirthYear")
Script.serveFunction("DatabaseAPI_SQLite.setPersonBirthMonth",  "setPersonBirthMonth")
Script.serveFunction("DatabaseAPI_SQLite.setPersonBirthDay",    "setPersonBirthDay")
Script.serveFunction("DatabaseAPI_SQLite.setSqlQuery",          "setSqlQuery")
Script.serveFunction("DatabaseAPI_SQLite.getSqlQuery",          "getSqlQuery")
Script.serveFunction("DatabaseAPI_SQLite.insert",               "insert")
Script.serveFunction("DatabaseAPI_SQLite.exec",                 "exec")
Script.serveFunction("DatabaseAPI_SQLite.execAllPersons",       "execAllPersons")
Script.serveFunction("DatabaseAPI_SQLite.execAvgBirthYear",     "execAvgBirthYear")
Script.serveFunction("DatabaseAPI_SQLite.execNumOfPersons",     "execNumOfPersons")
Script.serveFunction("DatabaseAPI_SQLite.execClearTablePerson", "execClearTablePerson")

-- Serving events
local localOnResultEventName     = "OnResult"
local localOnSqlChangeEventName  = "OnSqlChange"
Script.serveEvent("DatabaseAPI_SQLite.OnResult", localOnResultEventName)
Script.serveEvent("DatabaseAPI_SQLite.OnSqlQueryChange", localOnSqlChangeEventName)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

---triggers result-event
---@param text String
local function printResult(text)
  Script.notifyEvent(localOnResultEventName, text)
end

---sets global sqlQuery and triggers sql-changed event
---@param sql String
function updateSql(sql)
  sqlQuery = sql
  Script.notifyEvent(localOnSqlChangeEventName, sqlQuery)
end

---@param firstName String
function setPersonFirstName(firstName)
  personFirstName = firstName
end

---@param lastName String
function setPersonLastName(lastName)
  personLastName = lastName
end

---@param birthYear String
function setPersonBirthYear(birthYear)
  personBirthYear = birthYear
end

---@param birthMonth String
function setPersonBirthMonth(birthMonth)
  personBirthMonth = birthMonth
end

---@param birthDay String
function setPersonBirthDay(birthDay)
  personBirthDay = birthDay
end

---@param query String
function setSqlQuery(query)
  sqlQuery = query
end

---@return String sqlQuery
function getSqlQuery()
  return sqlQuery
end

---inserts dataset into the database
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


---executes query
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

function execAllPersons()
  updateSql("select * from Person")
  DatabaseAPI_SQLite.exec()
end

function execAvgBirthYear()
  updateSql("select avg(BirthYear) from Person")
  DatabaseAPI_SQLite.exec()
end

function execNumOfPersons()
  updateSql("select count(*) from Person")
  DatabaseAPI_SQLite.exec()
end

function execClearTablePerson()
  updateSql("delete from Person")
  DatabaseAPI_SQLite.exec()
end

---executes initializing of database as stored in the setup-file
---@param bd handle
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
