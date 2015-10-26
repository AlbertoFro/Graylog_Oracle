# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require 'socket' # for Socket.gethostname
require 'java'
#<span style="color: red;"># SETUP THE JDBC DRIVER TO YOUR LOCATION 
$CLASSPATH << "/opt/logstash/lib/ojdbc6.jar"
#</span>
 
java_import 'oracle.jdbc.OracleDriver'
java_import 'java.sql.DriverManager'
 
 
# Run sql line tools and capture the whole output as an event.
#
# Notes:
#
# * The '@source' of this event will be the sql run.
# * The '@message' of this event will be the entire stdout of the sql
#   as one event.
#
class LogStash::Inputs::OraSQL < LogStash::Inputs::Base
 
  config_name "orasql"
  milestone 2
    
  $currConnection = nil
 
  default :codec, "plain"
 
  # Set this to true to enable debugging on an input.
  config :debug, :validate => :boolean, :default => false, :deprecated => "This setting was never used by this plugin. It will be removed soon."
 
  # SQL to run. For example, "select * from emp"
  config :sql, :validate => :string, :required => true
 
  # dbuser to run. For example, "select * from emp"
  config :dbuser, :validate => :string, :required => true ,  :default => "/"
 
  # dbpass to run. For example, "select * from emp"
  config :dbpasswd, :validate => :string, :required => false , :default => ""
 
  # dburl to run. For example, "select * from emp"
  config :dburl, :validate => :string, :required => true , :default => "//localhost/orcl"
 
  # Interval to run the sql. Value is in seconds.
  config :interval, :validate => :number, :required => true , :default => 120
 
  public
  def register
    @logger.info("Registering SQL Input", :type => @type,
                 :sql => @sql, :interval => @interval)
  end # def register
   
  public 
  def getConnection
      if $currConnection == nil  or  ! $currConnection.isValid(100)  
           oradriver = OracleDriver.new
           DriverManager.registerDriver oradriver
 
           con_props = java.util.Properties.new
           con_props.setProperty("user", @dbuser)
           con_props.setProperty("password", @dbpasswd )
  
           conn =  Java::oracle.jdbc.OracleDriver.new.connect('jdbc:oracle:thin:@' + @dburl, con_props)
 
           conn.auto_commit = false
 
           $currConnection = conn
      end 
       
      return $currConnection  
        
  end # end getConnection
 
  public
  def run(queue)
    hostname = Socket.gethostname
    
    loop do
      start = Time.now
 #     @logger.info? && @logger.info("Running SQL", :sql => @sql)
 
      conn = getConnection
 
      stmt = conn.prepare_statement @sql
      rset = stmt.execute_query
      while ( rset.next )
         i=1
         event =  event = LogStash::Event.new
         decorate(event)
         cols = rset.getMetaData.getColumnCount
         msg = ""
         r=0
         while ( i <= cols ) 
             val = rset.getString(i)
             if ( val != nil ) 
                if ( r > 0 )
                   msg = msg + ","
                end
                event[ rset.getMetaData.getColumnName(i).downcase ] =  val
                msg = msg +  "\"" +rset.getMetaData.getColumnName(i).downcase +  "\" : \"" + val + "\""
                r=r+1
             end
             i = i + 1
         end
         event['message'] = "{" + msg + "}"
        queue << event
      end
      conn.close
 
      duration = Time.now - start
#      @logger.info? && @logger.info("Command completed", :sql => @sql,
#                                    :duration => duration)
 
      # Sleep for the remainder of the interval, or 0 if the duration ran
      # longer than the interval.
      sleeptime = [0, @interval - duration].max
      if sleeptime == 0
        @logger.warn("Execution ran longer than the interval. Skipping sleep.",
                     :sql => @sql, :duration => duration,
                     :interval => @interval)
      else
        sleep(sleeptime)
      end
    end # loop
  end # def run
end # class LogStash::Inputs::OraSQL
