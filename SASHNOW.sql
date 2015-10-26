 CREATE OR REPLACE FORCE VIEW "SYS"."SASHNOW" ("INST_ID", "DBID", "SAMPLE_TIME", "SESSION_ID", "SESSION_STATE", "SESSION_SERIAL#", "PROCESS", "OSUSER", "SESSION_TYPE", "USER_ID", "COMMAND", "MACHINE", "PORT", "SQL_ADDRESS", "SQL_PLAN_HASH_VALUE", "SQL_CHILD_NUMBER", "SQL_ID", "SQL_OPCODE", "SQL_EXEC_START", "SQL_EXEC_ID", "PLSQL_ENTRY_OBJECT_ID", "PLSQL_ENTRY_SUBPROGRAM_ID", "PLSQL_OBJECT_ID", "PLSQL_SUBPROGRAM_ID", "EVENT#", "SEQ#", "P1", "P2", "P3", "WAIT_TIME", "TIME_WAITED", "CURRENT_OBJ#", "CURRENT_FILE#", "CURRENT_BLOCK#", "CURRENT_ROW#", "PROGRAM", "MODULE", "MODULE_HASH", "ACTION", "ACTION_HASH", "LOGON_TIME", "KSUSEBLOCKER", "SERVICE_NAME", "FIXED_TABLE_SEQUENCE", "QC") AS 
  select
    s.INST_ID "INST_ID",
    d.dbid,
    sysdate sample_time,
    s.indx          "SESSION_ID",
	decode(s.ksusetim, 0,'WAITING','ON CPU') "SESSION_STATE",
    s.ksuseser      "SESSION_SERIAL#",
	s.ksusepid "PROCESS",
	s.ksuseunm      "OSUSER",
	s.ksuseflg      "SESSION_TYPE"  ,
    s.ksuudlui      "USER_ID",
	s.ksuudoct      "COMMAND",
    s.ksusemnm      "MACHINE",
    s.ksusemnp      "PORT",
    s.ksusesql      "SQL_ADDRESS",
    s.ksusesph      "SQL_PLAN_HASH_VALUE",
    decode(s.ksusesch, 65535, to_number(null), s.ksusesch) "SQL_CHILD_NUMBER",
    s.ksusesqi      "SQL_ID" ,    /* real SQL ID starting 10g */
    s.ksuudoct      "SQL_OPCODE"  /* aka SQL_OPCODE */,
    s.ksusesesta    "SQL_EXEC_START",
    decode(s.ksuseseid, 0, to_number(null), s.ksuseseid)                                                                  "SQL_EXEC_ID",
    decode(s.ksusepeo,0,to_number(null),s.ksusepeo)                                                                       "PLSQL_ENTRY_OBJECT_ID",
    decode(s.ksusepeo,0,to_number(null),s.ksusepes)                                                                       "PLSQL_ENTRY_SUBPROGRAM_ID",
    decode(s.ksusepco,0,to_number(null),decode(bitand(s.ksusstmbv, power(2,11)), power(2,11),s.ksusepco,to_number(null))) "PLSQL_OBJECT_ID",
    decode(s.ksusepcs,0,to_number(null),decode(bitand(s.ksusstmbv, power(2,11)), power(2,11),s.ksusepcs,to_number(null))) "PLSQL_SUBPROGRAM_ID",
    s.ksuseopc      "EVENT#",
    s.ksuseseq      "SEQ#"        /* xksuse.ksuseseq */,
    s.ksusep1       "P1"          /* xksuse.ksusep1  */,
    s.ksusep2       "P2"          /* xksuse.ksusep2  */,
    s.ksusep3       "P3"          /* xksuse.ksusep3  */,
    s.ksusetim      "WAIT_TIME"   /* xksuse.ksusetim */,
    s.ksusewtm      "TIME_WAITED" /* xksuse.ksusewtm */,
    s.ksuseobj      "CURRENT_OBJ#",
    s.ksusefil      "CURRENT_FILE#",
    s.ksuseblk      "CURRENT_BLOCK#",
    s.ksuseslt      "CURRENT_ROW#",
    s.ksusepnm      "PROGRAM",
    s.ksuseapp      "MODULE",
    s.ksuseaph      "MODULE_HASH",
    s.ksuseact      "ACTION",
    s.ksuseach      "ACTION_HASH",
    s.ksuseltm      "LOGON_TIME",
    s.ksuseblocker,
    s.ksusesvc      "SERVICE_NAME",
    s.ksusefix      "FIXED_TABLE_SEQUENCE", /* FIXED_TABLE_SEQUENCE */
    s.KSUSEQCSID    "QC"
    
from
    x$ksuse s , /* v$session */
    v$database d
where
    s.indx != ( select distinct sid from v$mystat  where rownum < 2 ) and
    bitand(s.ksspaflg,1)!=0 and
    bitand(s.ksuseflg,1)!=0 and
    (  (
        /* status Active - seems inactive & "on cpu"=> not on CPU */
        s.ksusetim != 0  and  /* on CPU  */
        bitand(s.ksuseidl,11)=1  /* ACTIVE */
    )
            or
    s.ksuseopc not in   /* waiting and the wait event is not idle */
        (  select event# from v$event_name where wait_class='Idle' )
    );
