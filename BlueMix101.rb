require 'rubygems'
require 'ibm_db'
require 'sinatra'
require 'json'
require 'haml' # template engine

# sample helloWorld program using DB2 services 
# v1.0   Felix Fong  27/04/2014   initial release 
# v1.1   Calvin Bui  28/04/2014   added array of messages, home button on each page and some visual improvement

# Global variables
BXMsg="Hello World from BlueMix Cloud!"
servicename = "SQLDB-1.0"
CurTime=Time.new.usec.to_s
jsondb_db = JSON.parse(ENV['VCAP_SERVICES'])[servicename]
credentials = jsondb_db.first["credentials"]
host = credentials["host"]
username = credentials["username"]
password = credentials["password"]
database = credentials["db"]
db2_port = credentials["port"]
tablename = "BLUEMIX.HelloWorldDemo"
dsn = "DRIVER={IBM DB2 ODBC DRIVER};DATABASE="+database+";HOSTNAME="+host+";PORT="+db2_port.to_s()+";PROTOCOL=TCPIP;UID="+username+";PWD="+password+";"
conn = IBM_DB.connect(dsn, '', '')
app_port = ENV['VCAP_APP_PORT']
parsed = JSON.parse(ENV['VCAP_APPLICATION'])
app_instance = parsed["instance_index"]+1
url  = parsed["application_uris"]
url2 = url.slice!(3..url.length-2)
messages = ["Welcome to BlueMix Cloud", "BlueMix - the new Platform as a Service Cloud from IBM", "200 BlueMix Days is on", "BlueMix  mixes with DevOps equals dream platform for developers", "Sign up BlueMix today!!!"]


get '/' do
  "
  <html>
  <head>
  <meta http-equiv='refresh' content='30'>
  <link href='css/bootstrap.css' rel='stylesheet' type='text/css' />
  </head>
  <body>
  <div class='container'>
  <h1>#{BXMsg} on port #{app_port} running on instance # #{app_instance} </h1>
  <a href=#{url2}>Refresh page</a> 
  <br>
  <br> 
  <a href=#{url2}/cr_tables>Create DB2 tables </a>
  <br>
  <a href=#{url2}/insert_tables>Insert into tables </a>
  <br>
  <a href=#{url2}/show_tables>Display all records </a>
  <br> 
  <a href=#{url2}/cleanup_tables>Clean up tables </a>
  </div>
  </body>
  </html>
  "
end 

get '/cr_tables' do 
    total = String.new
    total += "<head><link href='css/bootstrap.css' rel='stylesheet' type='text/css'/></head><body><div class='container'>"
    total += "Connect to DB2 Database using Ruby Sinatra and the DB2 ODBC driver<BR><BR>\n"
    
    out = String.new


    total = total + "Connecting to " + dsn + "<BR><BR>\n"
    if conn = IBM_DB.connect(dsn, '', '')
      sql = "CREATE TABLE " + tablename + " (MESSAGES VARCHAR(200), INSTANCE_ID INT, PORT_NO INT)"
      if stmt = IBM_DB.exec(conn, sql)
        total = total + sql + "<BR><BR>\n"
      else
        out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
        total = total + out + "<BR>\n"
      end
    else
      out = "Connection failed: #{IBM_DB.conn_errormsg}"
      total = total + out + "<BR><BR>\n"
    end # connect
    total += "<a href=#{url2}/>Return to homepage </a></div></body>"
    total  # display messages
end  # get


get '/insert_tables' do

    # Insert some records
    total = String.new
    total += "<head><link href='css/bootstrap.css' rel='stylesheet' type='text/css'/></head><body><div class='container'>"
    dbvalue = messages.sample
    total += "<h2>" + dbvalue + "</h2>" 
    total += "<h4>   (This app is running on port #{app_port} running on instance # #{app_instance}) </h4><BR>"
    sql = "INSERT INTO " + tablename + " VALUES ('" + dbvalue + "', #{app_port}, #{app_instance})"
    total = total + sql + "<BR><BR>\n"
    IBM_DB.exec(conn, sql)
    total += "<a href=#{url2}/insert_tables>Insert more data</a><br/>"
    total += "<a href=#{url2}/>Return to homepage </a></div></body>"
    total

end

get '/show_tables' do

    # run a select query
    total = String.new
    total += "<head><link href='css/bootstrap.css' rel='stylesheet' type='text/css'/></head><body><div class='container'>"
    sql = "SELECT * FROM " + tablename
    total += sql + "<BR><BR>"

    begin
       if stmt = IBM_DB.exec(conn, sql)
          total += "<table class='table table-condensed table-striped'><th>DB Messages</th>"
          # iterate through the result set
          while row = IBM_DB.fetch_assoc(stmt)
            total += "<tr><td>"
            out = "#{row['MESSAGES']}  #{row['INSTANCE_ID']}  #{row['PORT_NO']}"
            total += out + "</td></tr>"
          end
          # free the resources associated with the result set
          IBM_DB.free_result(stmt)
          total += "</table>"
        else
          out = "Statement execution failed: #{IBM_DB.stmt_errormsg}"
          total = total + out + "<BR>\n"
        end
    ensure
       total
    end 
    total += "<a href=#{url2}/>Return to homepage </a></div></body>"
    total
end

get '/cleanup_tables' do
  # Cleanup, drop the table and close the database connection
    total = String.new
    total += "<head><link href='css/bootstrap.css' rel='stylesheet' type='text/css'/></head><body><div class='container'>"
    out = String.new
    total += "Connecting to " + dsn + "<BR>\n"
    conn = IBM_DB.connect(dsn, '', '')
    total = total + "<BR>"
    sql = "DROP TABLE " + tablename 
    total = total + sql + "<BR>\n"
    IBM_DB.exec(conn, sql)
    total = total + "Closing Database <BR><BR>\n"
    IBM_DB.close(conn)
    total += "<a href=#{url2}/>Return to homepage </a></div></body>"
    total
end 