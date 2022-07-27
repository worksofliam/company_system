**free
Ctl-Opt DFTACTGRP(*no);

Dcl-Pi EMPLOYEE;
  EMPNO Char(6);
End-Pi;

// ---------------------------------------------------------------*

/COPY 'qrpgleref/constants.rpgle'

// ---------------------------------------------------------------*

// Dcl-F emps WORKSTN Sfile(SFLDta:Rrn) IndDS(WkStnInd) InfDS(fileinfo);

Dcl-C SQLSUCCESS '00000';

Dcl-S Exit Ind Inz(*Off);

// Bad definition for RRN...
Dcl-S Rrn          Zoned(4:0) Inz;
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

Dcl-S Index Int(5);

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
      HandleInputs();
  Endsl;
Enddo;

*INLR = *ON;
Return;

// ------------------------------------------------------------

Dcl-Proc ClearSubfile;
  SflDspCtl = *Off;
  SflDsp = *Off;

  Write SFLCTL;

  SflDspCtl = *On;

  rrn = 0;
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
              WHERE WORKDEPT = :DEPTNO;

  EXEC SQL OPEN empCur;

  if (sqlstate = SQLSUCCESS);

    dou (sqlstate <> SQLSUCCESS);
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
      endif;
    enddo;

  endif;

  EXEC SQL CLOSE empCur;

  If (rrn > 0);
    SflDsp = *On;
    SFLRRN = 1;
  Endif;
End-Proc;

Dcl-Proc HandleInputs;
  Dcl-S SelVal Char(1);

  Dou (%EOF(emps));
    ReadC SFLDTA;
    If (%EOF(emps));
      Iter;
    Endif;

    SelVal = %Trim(XSEL);

    Select;
      When (SelVal = '5');
        DSPLY XID;
    Endsl;

    If (XSEL <> *Blank);
      XSEL = *Blank;
      Update SFLDTA;
      SFLRRN = rrn;
    Endif;
  Enddo;
End-Proc;
