
/*************** Create IR, Unemployment, GDP List -- For Example **********************************************************************************/
%Load_Data(File_Name=, output=JJCRE.MEV_CRE_All, sheet=MEV_List_CRE, filetype=);
%Load_Data(File_Name=, output=JJCRE.MEV_IR, sheet=IR, filetype=);

%Convert_MEV_List_1(input=JJCRE.MEV_CRE_All, column=MEV_List_CRE_All, List_Name=MEV_CRE_All_List);
%Convert_MEV_List_1(input=JJCRE.MEV_IR, column=MEV_List_CRE_CNI_IR, List_Name=MEV_IR_List);





%let Total_Num_MEV = 41;
%let Max_num_MEV_select = 3;
%let Min_num_MEV_select = 3;



data Combination1;
 array x[&Total_Num_MEV.] $6000 &MEV_CNI_All_List.;
 array h[&Max_num_MEV_select.] $6000 ;
 array l[&Max_num_MEV_select.];

 do k=&Min_num_MEV_select. to &Max_num_MEV_select.;
 ncomb=comb(&Total_Num_MEV., k);
 n = dim(x);
 call sortc(of x(*));
 /* empty target array*/
 call missing (of h(*));
 l[1] = 0;

 do j=1 to ncomb;
 retain Group_1 Group_2 Group_3 Group_4 Group_5 Group_6 Group_7 Group_8 Group_9 Group_10;
 Group_1 = 0;
 Group_2 = 0;
 Group_3 = 0;
 Group_4 = 0;
 Group_5 = 0;
 Group_6 = 0;
 Group_7 = 0;
 Group_8 = 0;
 Group_9 = 0;
 Group_10 = 0;
/* Group_11 = 0;*/
 call allcombi(n, k, of l[*]);

 do i=1 to k;
 h[i]=x[l[i]];
 if h[i] in &MEV_IR_List. then Group_1 = Group_1 + 1;
 if h[i] in &MEV_INFLA_List. then Group_2 = Group_2 + 1;
 if h[i] in &MEV_CS_List. then Group_3 = Group_3 + 1;
 if h[i] in &MEV_CREPI_List. then Group_4 = Group_4 + 1;
 if h[i] in &MEV_EI_List. then Group_5 = Group_5 + 1;
 if h[i] in &MEV_Industry_List. then Group_6 = Group_6 + 1;
 if h[i] in &MEV_CorpProfit_List. then Group_7 = Group_7 + 1;
 if h[i] in &MEV_GDP_List. then Group_8 = Group_8 + 1;
 if h[i] in &MEV_Unemp_List. then Group_9 = Group_9 + 1;
 if h[i] in &MEV_S_CSCurve_List. then Group_10 = Group_10 + 1;
/* if h[i] in &MEV_CSCurve_List. then Group_11 = Group_11 + 1;*/
 end;
 if Group_1 > 1 then continue;
 if Group_2 > 1 then continue;
 if Group_3 > 1 then continue;
 if Group_4 > 1 then continue;
 if Group_5 > 1 then continue;
 if Group_6 > 1 then continue;
 if Group_7 > 1 then continue;
 if Group_8 > 1 then continue;
 if Group_9 > 1 then continue;
 if Group_10 > 1 then continue;
/* if Group_11 > 1 then continue;*/
 Var_Comb = catx(" ", of h(*));
 output;
 end;
 end;
 keep Var_Comb;
run;




data JJCRE.Combination_CNI;
 set Combination1;
run;



/***** Create Temp File used in Ex-Search *******/
Data _Temp_1;
 Candidate = 1;
 R2 = 1;
 RMSE = 1;
 output;
Run;


/******** Filter Selected Variables for Following Steps ********/
Data MEV_All_Selected;
 set MEV_All;
  where selection_Logic = "Y";
 Run;


/******************************************************* Stationary Test **************************************************************************************/
%stationary_test_result(dsn=masterfile, var_list=MEV_All_Selected, outdsn=All_Stationary_Results, beg_num=1, end-num=200, col_name=MEV_List_All);

/***Summarize the MEVs that Pass Either Zero mane or Single Mean *****/
proc SQL noprint;
  create table st_variable_single as
  select distinct variable
  from All_Stationary_Results
  where type in ("Single Mean")
  group by variable
  having max(probtau) <= 0.05;
Run;

proc SQL noprint;
  create table st_variable_zero as
  select distinct variable
  from All_Stationary_Results
  where type in ("Zero Mean")
  group by variable
  having max(probtau) <= 0.05;
Run;

/** we can also use > 0.05 to focus those failed the st test **/

Data st_variable_all;
 set st_variable_zero  st_variable_single;
Run;




/******* Before P-Value and Other Test *********/
Data _null_;
  set EX_Search_Output end=eof;
  Var_All = strip(Var_Chg) || " " || strip(Var_NoChg);
  call symputx(cats('E', put(_n_, 8.)), Var_All);
  call symputx(cats('R', put(_n_, 8.)), R2);
  call symputx(cats('RMSE', put(_n_, 8.)), RMSE);
  call symputx(cats('Candidate', put(_n_, 8.)), Candidate);
  if eof then call symputx('max', _n_);
Run;


%put ************* &E2.  &max.  &R2.  &RMSE.  &Candidate.;



%p_vif_test(dsn=masterfile, tar_var=target, outdsn=Final_Candidate_Stats);

Proc dataset lib=work nolist nowarn;
  delete _Param_Reg_: ;
Run;

Proc sort data=Final_Candidate_Stats;
  by descending R2 order;
Run;

Data Final_Candidate_Stats;
  set Final_Candidate_Stats;
  format Estimate comma16.5  R2 comma16.3;
Run;

Data xx.Final_Candidate_Stats;
  set Final_Candidate_Stats;
Run;



/******** Filter out Candidate Models that Pass P-Value VIF and has R2 > than xx% ***********/
Data pass_candidate;
  set xx.Final_Candidate_Stats;
  where pvalue_check='Significant'  and VIF_check='Passed'  and R2>=xx;
Run;

Proc SQL;
  create table pass_candidate2 as
  select *, count(variable) as passed_var
  from passcandidate
  group by candidate;
Run;

data pass_candidate_f;
  set pass_candidate2;
  where passed_var = 4;
Run;


Proc SQL;
  create table pass_candidates_list as
  select distince candidate
  from pass_candidates_f;
Quit;


Proc SQL;
  create table Ex_Search_2 as
  select a.*,  b.*
  from pass_candidates_list as a
  inner join EX_Search_Output  as b
  on a.candidate = b.candidate;
Quit;

Data test;
  set Ex_Search_2;
  where candidate = 46688;
Run;


Data _null_;
  set test end=eof;
  Var_All = strip(Var_Chg) || " " || strip(Var_NoChg);
  call symputx(cats('E', put(_n_, 8.)), Var_All);
  call symputx(cats('R', put(_n_, 8.)), R2);
  call symputx(cats('RMSE', put(_n_, 8.)), RMSE);
  call symputx(cats('Candidate', put(_n_, 8.)), Candidate);
  if eof then call symputx('max', _n_);
Run;



%Other_test(dsn1=masterfile, dsn2=test, tar_var=target, outdsn=test2);


Proc SQL;
  create table  _Temp_data_1_0 as
  select a.*,
         b.RMSE,
         b.normality_flag,
         b.autocorr_flag,
         b.ramsey_flag,
         b.arch_flag,
         b.var_chg
  from pass_candidates_f as a
  left join
  Candidate_NOV as b
  on
  a.candidate = b.candidate;
Run;






/******************************************************* Piecewise Regression **************************************************************************************/
/******************************************************* Piecewise Regression **************************************************************************************/
/******************************************************* Piecewise Regression **************************************************************************************/

proc adaptivereg data=abc  details=BASES plots=all;
   model Target = Variable / maxbasis=50  maxorder=5;
   output out=Temp_1  predicted=Pred;
Run;






