**free
Ctl-Opt DFTACTGRP(*no);

Dcl-Pi EMPLOYEE;
  EMPNO Char(6);
End-Pi;

// ---------------------------------------------------------------*

/COPY 'qrpgleref/constants.rpgle'

// ---------------------------------------------------------------*

Dcl-F emp WORKSTN IndDS(WkStnInd) InfDS(fileinfo);

Dcl-C SQLSUCCESS '00000';

Dcl-S Exit Ind Inz(*Off);

// /Indicators for the workstation
///

Dcl-DS WkStnInd;
  ProcessSCF     Ind        Pos(21);
  ReprintScf     Ind        Pos(22);
  Error          Ind        Pos(25);
  PageDown       Ind        Pos(30);
  PageUp         Ind        Pos(31);
  SflEnd         Ind        Pos(40);
  SflBegin       Ind        Pos(41);
  NoRecord       Ind        Pos(60);
  SflDspCtl      Ind        Pos(85);
  SflClr         Ind        Pos(75);
  SflDsp         Ind        Pos(95);
End-DS;

Dcl-DS FILEINFO;
  FUNKEY         Char(1)    Pos(369);
End-DS;

// ---------------------------------------------------------------*

Dcl-Ds Employee ExtName('EMPLOYEE') Alias Qualified;
End-Ds;

// ------------------------------------------------------------reb04
Exit = *Off;
LoadSubfile();

Dow (Not Exit);
  Write FOOTER_FMT;
  Exfmt SFLCTL;

  Select;
    When (Funkey = F12);
      Exit = *On;
    When (Funkey = ENTER);
  Endsl;
Enddo;

*INLR = *ON;
Return;

// ------------------------------------------------------------

Dcl-Proc ClearSubfile;
  SflDspCtl = *Off;
  SflDsp = *Off;

  Write SFLCTL;
End-Proc;

Dcl-Proc LoadSubfile;
  Dcl-S lCount  Int(5);
  Dcl-S Action  Char(1);
  Dcl-S LongAct Char(3);

  ClearSubfile();

  EXEC SQL DECLARE empCur CURSOR FOR
    SELECT
      EMPNO,
      FIRSTNME, MIDINIT, LASTNAME,
      JOB, HIREDATE, EDLEVEL,
      SALARY, BONUS, COMM
    FROM EMPLOYEE
    WHERE EMPNO = :EMPNO;

  EXEC SQL OPEN empCur;

  if (sqlstate = SQLSUCCESS);

    EXEC SQL
        FETCH NEXT FROM empCur
        INTO :Employee.EMPNO,
              :Employee.FIRSTNME,
              :Employee.MIDINIT,
              :Employee.LASTNAME,
              :Employee.JOB,
              :Employee.HIREDATE,
              :Employee.EDLEVEL,
              :Employee.SALARY,
              :Employee.BONUS,
              :Employee.COMM;

    if (sqlstate = SQLSUCCESS);
      // Write to display file here.
      XID = Employee.EMPNO;
      XJOB = Employee.JOB;
      XNAME = %trimr(Employee.FIRSTNME) + ' ' %trimr(Employee.LASTNAME);
    endif;

    Write FOOTER_FMT;
    Exfmt BASE_FMT;

  endif;

  EXEC SQL CLOSE empCur;
End-Proc;