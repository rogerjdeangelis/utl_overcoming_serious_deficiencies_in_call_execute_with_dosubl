Overcoming serious deficiencies in call execeute with dosubl

This is a classic case where blacksheep DOSUBL clears up many defiiciencies of 'call execute';

* Problem;

data _null_;
if &nrows. = 0 then call execute('%norecs');
else call execute('%recs');
run;

Form Astounding

You're actually looking at a quirk of CALL EXECUTE here.  It runs macro code immediately,
but runs SAS language code (DATA and PROC steps) later.  In this case, when CALL EXECUTE
generates:  %recs the %PUT statement attempts to run immediately.  But at that point
&N doesn't exist yet.  The DATA and PROC steps run later, creating &N but it is too late at
that point.  The generic fix
for this sort of issue:


profile Astounding
https://communities.sas.com/t5/user/viewprofilepage/user-id/4954

SAS forum
https://communities.sas.com/t5/Base-SAS-Programming/Resolving-a-Macro-Variable-within-a-Macro/m-p/466488


INPUT
=====

   RULES
     Execute
       Regression if sashelp.class has male students
       else execute proc freq on sex

   SASHELP.CLASS

   Bunch of global macro variables before call subroutines to
   detemine conditions for the reports.

   %let  nofac     = 5  ;
   %let  obscount  = 10 ;
   %let  fini_total= 5  ;
   %let  nrows     = 0  ;

 Example output in the log

  Regression Completed
   or
  Frequency Completed
   or
  Error Check the log


PROCESS
=======

 /* I left out stuff that seems to only create a bunch of global macro variables */

 %let  nofac     = 5  ;
 %let  obscount  = 10 ;
 %let  fini_total= 5  ;
 %let  nrows     = 0  ;

 * just in case they exist - always a problem? */
 %symdel n nrows / nowarn;

 data log;

   if _n_=0 then do;

       * set nrows bases on sex (if sex=X then nrows=0);
       %let rc=%sysfunc(dosubl('
          proc sql;
            select count(*) into :nrows from sashelp.class where sex="M"
          ;quit;
       '));
   end;

   * load the global macro variables;
   retain nrows       &nrows
          nofac       &nofac
          obscount    &obscount
          fini_total  &fini_total
          nrows       &nrows
          freq        1
          reg         1
      ;

   * set the number of obs for proc reg and proc freq;
   if nofac < obscount then call symputx ("N",&obscount);
   else if nofac > fini_total then call symputx ("N",&fini_total);
   else call symputx ("N",&nofac);

   if nrows > 0 then do;
      reg=dosubl('
          proc reg data=sashelp.class(obs=&n.);
              model height=weight;
          run;quit;
      ');
   end;
   else do;
       freq=dosubl('
          proc freq data=sashelp.class(obs=&n);
            tables sex;
          run;quit;
       ');
   end;

   if reg=0 then putlog "Regression was Completed";
   else if freq=0 then putlog "Frequency was Completed";
   else putlog "EROOR CHECK LOG";

 run;quit;


OUTPUT IN THE LOG
=================

  Regression Completed
   or
  Frequency Completed
   or
  Error Check the log

*                _              _       _
 _ __ ___   __ _| | _____    __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \  / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/ | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|  \__,_|\__,_|\__\__,_|

;

   SASHELP.CLASS

   Bunch of global macro variables before call subroutines to
   detemine conditions for the reports.

   %let  nofac     = 5  ;
   %let  obscount  = 10 ;
   %let  fini_total= 5  ;
   %let  nrows     = 0  ;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __
/ __|/ _ \| | | | | __| |/ _ \| '_ \
\__ \ (_) | | |_| | |_| | (_) | | | |
|___/\___/|_|\__,_|\__|_|\___/|_| |_|

;

see process

