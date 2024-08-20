
/************** Fractional Polynomical Transformation (Enhanced Version) -- Start **********************************************************************************************************************/
/************** Fractional Polynomical Transformation (Enhanced Version) -- Start **********************************************************************************************************************/
/************** Fractional Polynomical Transformation (Enhanced Version) -- Start **********************************************************************************************************************/



%macro FP_const(raw_data=, temp_data=, var=, Var_NoChg=, Category1=, range1=, range2=, term=, Prepay=, SMM=,);

 data &temp_data;
 set &raw_data;
 keep ACCOUNT file_date &Prepay. Full_Prepay_Bal &SMM. &var. &Var_NoChg. &Category1.;
 run;



 data &temp_data;
 set &temp_data;
 format percent_&var. log_&var. log2_&var. &var._revsq log_&var._revsq log2_&var._revsq &var._rev log_&var._rev
 log2_&var._rev &var._revsqrt log_&var._revsqrt log2_&var._revsqrt &var._sqrt log_&var._sqrt log2_&var._sqrt
 log_&var._&var. log2_&var._&var. &var._sq log_&var._sq log2_&var._sq comma16.3;

 percent_&var.=0;
 log_&var.=0;
 log2_&var.=0;
 &var._revsq=0;
 log_&var._revsq=0;
 log2_&var._revsq=0;
 &var._rev=0;
 log_&var._rev=0;
 log2_&var._rev=0;
 &var._revsqrt=0;
 log_&var._revsqrt=0;
 log2_&var._revsqrt=0;
 &var._sqrt=0;
 log_&var._sqrt=0;
 log2_&var._sqrt=0;
 log_&var._&var.=0;
 log2_&var._&var.=0;
 &var._sq=0;
 log_&var._sq=0;
 log2_&var._sq=0;



 if &range1. <= &var. <= &range2. and &Category1.=&term. then
 do;
 percent_&var.=&var./100;
 log_&var. = log(percent_&var.);
 log2_&var. = log_&var. * log_&var.;
 &var._revsq = 1/(percent_&var. * percent_&var.);
 log_&var._revsq = &var._revsq * log_&var.;
 log2_&var._revsq = &var._revsq * log2_&var.;
 &var._rev = 1/percent_&var.;
 log_&var._rev = &var._rev * log_&var.;
 log2_&var._rev = &var._rev * log2_&var.;
 &var._revsqrt = 1/sqrt(percent_&var.);
 log_&var._revsqrt = &var._revsqrt * log_&var.;
 log2_&var._revsqrt = &var._revsqrt * log2_&var.;
 &var._sqrt = sqrt(percent_&var.);
 log_&var._sqrt = &var._sqrt * log_&var.;
 log2_&var._sqrt = &var._sqrt * log2_&var.;
 log_&var._&var. = percent_&var. * log_&var.;
 log2_&var._&var. = percent_&var. * log2_&var.;
 &var._sq = percent_&var. * percent_&var.;
 log_&var._sq = &var._sq * log_&var.;
 log2_&var._sq = &var._sq * log2_&var.;
 end;
 run;

%mend FP_const;









%macro Exhau_Search_FP(dsn1=, dsn2=, tempdsn=, var_list_nochg=, outdsn=, var_FP=, term=, Category1=, beg_num=, end_num=, Prepay=, SMM=,);

 %do i=&beg_num. %to &end_num.;

 data _null_;
 set &dsn1.;
 if _n_ = &i. then CALL SYMPUT ('var_FPT_local', Var_Comb); 
 run;

 %put ******** &var_FPT_local.;
 %put ******** &i.;

 Proc logistic Data=&dsn2.;
 model &Prepay. / Full_Prepay_Bal = &var_list_nochg. &var_FPT_local. / link=logit;
 output out=Prediction(keep=ACCOUNT FILE_DATE &var_FP. &var_FPT_local. &Category1. &Prepay. Full_Prepay_Bal &SMM. Pred) Predicted=Pred;
 Run;


 Data Prediction;
 set Prediction;
 Pred_PrepayAMT = Pred * Full_Prepay_Bal;
 Run;




 Proc SQL;
 create table _Temp_Agg_0 as
 select
 &var_FP.,
 sum(&Prepay.) as Sum_Prepay_Actual,
 sum(Pred_PrepayAMT) as Sum_Prepay_Pred,
 sum(Full_Prepay_Bal) as Sum_Bal,
 calculated Sum_Prepay_Actual / calculated Sum_Bal as SMM_Actual,
 calculated Sum_Prepay_Pred / calculated Sum_Bal as SMM_Pred,
 calculated SMM_Pred - calculated SMM_Actual as Residual,
 calculated Residual * calculated Residual as Sq_Error
 from
 Prediction
 where
 &Category1. = &term. and &var_FP. > 0
 group by
 &var_FP.;
 Run;




 Proc SQL;
 select
 count(*) as Total_Obs,
 avg(Sq_Error) as MSE,
 sqrt(calculated MSE) as RMSE into :Obs, :MSE, :RMSE
 from
 _Temp_Agg_0;
 Run;




 %if &i. = 1 %then
 %do;

 Data &outdsn.;
 set &tempdsn.;
 informat Var_Chg $10000. Var_NoChg $10000.;

 Var_Chg = "&var_FPT_local.";
 Var_NoChg = "&var_list_nochg.";
 Candidate = &i.;
 RMSE = &RMSE.;
 Run;

 %end;

 %else %do;
 Data _Temp_2;
 set &tempdsn.;
 informat Var_Chg $10000. Var_NoChg $10000.;

 Var_Chg = "&var_FPT_local.";
 Var_NoChg = "&var_list_nochg.";
 Candidate = &i.;
 RMSE = &RMSE.;
 Run;

 Proc append base=&outdsn. data=_Temp_2;
 run;
 %end;


 %end;
%mend Exhau_Search_FP;
/************** Graph Macro -- Start **********************************************************************************************************************/
/************** Graph Macro -- Start **********************************************************************************************************************/
/************** Graph Macro -- Start **********************************************************************************************************************/


%Macro Graph(dsn=, item=, x_axis=, y_axis1=, y_axis2=, y_axis3=, y_axis_label=, color1=, color2=, pattern1=, pattern2=);

 %if &item.= 1 %then
 %do;
 ods graphics on / width=10in height=5in;
 Proc sgplot data=&dsn.;
 title "&y_axis1.";
 series y=&y_axis1. x=&x_axis. / lineattrs=(color=&color1. pattern=&pattern1.) smoothconnect name="L1" legendlabel="&y_axis1." ;

 xaxis label="&x_axis." grid Fitpolicy=rotatethin;
 yaxis label="&y_axis_label.";
 keylegend "L1";
 Run;
 title;
 %end;



 %if &item.= 2 %then
 %do;
 ods graphics on / width=10in height=5in;
 Proc sgplot data=&dsn.;
 title "&y_axis1.";
 series y=&y_axis1. x=&x_axis. / lineattrs=(color=&color1. pattern=&pattern1.) smoothconnect name="L1" legendlabel="&y_axis1." ;
 series y=&y_axis2. x=&x_axis. / lineattrs=(color=&color2. pattern=&pattern2.) lineattrs=(thickness=3) smoothconnect name="L2" legendlabel="&y_axis2." ;

 xaxis label="&x_axis." grid Fitpolicy=rotatethin;
 yaxis label="&y_axis_label.";
 keylegend "L1" "L2";
 Run;
 title;
 %end;


 %if &item.= 3 %then
 %do;
 ods graphics on / width=10in height=5in;
 proc sgplot data=&dsn.;
 title "&y_axis1.";
 vline &x_axis. / response=&y_axis1. lineattrs=(color=&color1. pattern=&pattern1.) name="L1" legendlabel="&y_axis1." ;
 vbar &x_axis. / response=&y_axis3. y2axis barwidth=1 nooutline fillattrs=(color=gainsboro transparency=0.65) name="L2" legendlabel="&y_axis3." ;

 xaxis label="&x_axis." grid Fitpolicy=rotatethin;
 yaxis label="&y_axis_label.";
 keylegend "L1" "L2";
 run;
 title;
 %end;


 %if &item.= 4 %then
 %do;
 ods graphics on / width=10in height=5in;
 proc sgplot data=&dsn.;
 title "&y_axis1.";
 vline &x_axis. / response=&y_axis1. lineattrs=(color=&color1. pattern=&pattern1.) name="L1" legendlabel="&y_axis1." ;
 vline &x_axis. / response=&y_axis2. lineattrs=(color=&color2. pattern=&pattern2.) name="L2" legendlabel="&y_axis2." ;
 vbar &x_axis. / response=&y_axis3. y2axis barwidth=1 nooutline fillattrs=(color=gainsboro transparency=0.65) name="L3" legendlabel="&y_axis3." ;

 xaxis label="&x_axis." grid Fitpolicy=rotatethin;
 yaxis label="&y_axis_label.";
 keylegend "L1" "L2" "L3";
 run;
 title;
 %end;


%mend Graph;




**************************************************************************************************************

alywas fill: dsn, item, x_axis, y_axis_label, color1, pattern1

item 1: 1 curve. Fill y_axis1, color1 and pattern1

item 2: 2 curves. Fill y_axis1, y_axis2, color1, color2, pattern1 and pattern2

item 3: 1 curve and balance background. Fill y_axis1 (curve), y_axis2 (balance), color1 and pattern1 
 (no need to fill color2 and pattern2, Balance setup is in default)

item 4: 2 curves with balance gackground. Fill y_axis1 (curve1), y_axis2 (curve2), y_axis3 (balance)
 color1 (curve1), color2 (curve2), pattern1 (curve1) and pattern2 (curve2)
 (no need to fill color3 and pattern3, Balance setup is in default)

**************************************************************************************************************;














/************** Data Upload and Export -- Start **********************************************************************************************************************/
/************** Data Upload and Export -- Start **********************************************************************************************************************/
/************** Data Upload and Export -- Start **********************************************************************************************************************/


%Macro Load_Data(File_Name=, output=, sheet=, filetype=);
 Proc Import Out=&output.
 DATAFILE = &File_Name.
 DBMS = &filetype. Replace;
 SHEET = &sheet.;
 GETNAMES = YES; 
 Run;
%Mend Load_MEV;



%Macro Export_Data(DataFile=, output=, filetype=);
 Proc export Data = &DataFile.
 outfile= &output.
 dbms=&filetype.
 replace;
 Run;
%Mend Load_MEV;















/************** Stationary Check -- Start **********************************************************************************************************************/
/************** Stationary Check -- Start **********************************************************************************************************************/
/************** Stationary Check -- Start **********************************************************************************************************************/


%Macro Stationary_test(indsn=, var=, dif=, lag=);

 ods trace on;
 proc arima data=&indsn.;
 ods output StationarityTests=Stationarity;
 identify var=&var. (&dif.) nlag=&lag. stationarity=(adf) clear;
 run;
 ods trace off;

%Mend Stationary_test;




%macro Stationary_test_result(dsn=, var_list=, outdsn=, beg_num=, end_num=, Col_name=,);

 proc delete data=&outdsn.; run;
 
 %do i=&beg_num. %to &end_num.;

 data _null_;
 set &var_list.;
 if _n_ = &i. then CALL SYMPUT ('MEVs', &Col_name.); 
 run;

 %global &MEVs.;
 %put ******** MEVs: &MEVs.;
 %put ******** Loop: &i;

 %Stationary_test(indsn=&dsn., var=&MEVs., dif=0, lag=0);

 data st_&i.;
 set Stationarity;
 format variable $255.;
 variable = "&MEVs.";
 run;

 proc append base=&outdsn. data=st_&i.; run;

 proc delete data=work.st_&i.; run;

 %end;

%mend Stationary_test_result;
/************** Create MEV List 1) with , 2) without , -- Start **********************************************************************************************************************/
/************** Create MEV List 1) with , 2) without , -- Start **********************************************************************************************************************/
/************** Create MEV List 1) with , 2) without , -- Start **********************************************************************************************************************/



%Macro Convert_MEV_List_1(input=, column=, List_Name=,);

 Proc SQL noprint;
 select
 distinct quote(strip(&column.)) into :temp_name1 separated by " "
 from
 &input.;
 quit;

 %global &List_Name.;
 %let &List_Name. = %str((&temp_name1.));

%Mend Convert_MEV_List_1;


%Macro Convert_MEV_List_2(input=, column=, List_Name=,);

 Proc SQL noprint;
 select
 distinct quote(strip(&column.)) into :temp_name1 separated by ","
 from
 &input.;
 quit;

 %global &List_Name.;
 %let &List_Name. = %str((&temp_name1.));

%Mend Convert_MEV_List_2;


























/************** Exhausitive Search for Portfolio Level (PPNR) -- Start **********************************************************************************************************************/
/************** Exhausitive Search for Portfolio Level (PPNR) -- Start **********************************************************************************************************************/
/************** Exhausitive Search for Portfolio Level (PPNR) -- Start **********************************************************************************************************************/



%macro Exhau_Search_PPNR(dsn=, tempdsn=, var_list_nochg=, outdsn=, tar_var=, beg_num=, end_num=, combin=,);
 
 %do i=&beg_num. %to &end_num.;

 data _null_;
 set &combin.;
 if _n_ = &i. then CALL SYMPUT ('MEVs', Var_Comb); 
 run;

 %global &MEVs.;
 %put ******** MEVs: &MEVs.;
 %put ******** Loop: &i;


 Proc Reg Data=&dsn. outest=est1 rsquare;
 model &tar_var. = &MEVs. &var_list_nochg.;
 Run;


 Data est1;
 set est1 ;
 call symput("R2", _RSQ_);
 call symput("RMSE", _RMSE_);
 Run;



 %if &i. = 1 %then
 %do;

 Data &outdsn.;
 set &tempdsn.;
 informat Var_Chg $10000. Var_NoChg $10000.;

 Var_Chg = "&MEVs.";
 Var_NoChg = "&var_list_nochg.";
 R2 = &R2.;
 Candidate = &i.;
 RMSE = &RMSE.;
 Run;

 %end;

 %else %do;
 Data _Temp_2;
 set &tempdsn.;
 informat Var_Chg $10000. Var_NoChg $10000.;

 Var_Chg = "&MEVs.";
 Var_NoChg = "&var_list_nochg.";
 R2 = &R2.;
 Candidate = &i.;
 RMSE = &RMSE.;
 Run;

 Proc append base=&outdsn. data=_Temp_2;
 run;
 %end; 

 %end;
%mend Exhau_Search_PPNR;
















/************** P-value and VIF Test (PPNR) -- Start **********************************************************************************************************************/
/************** P-value and VIF Test (PPNR) -- Start **********************************************************************************************************************/
/************** P-value and VIF Test (PPNR) -- Start **********************************************************************************************************************/



%macro P_VIF_Test_PPNR(dsn=, tar_var=, outdsn=);

 proc delete data=&outdsn.; run;

 %do i=1 %to (&max. - 1);

 %put ******** MEVs: &&E&i.;
 %put ******** Loop: &i;


 Proc Reg Data=&dsn. ;
 model &tar_var. = &&E&i. / vif;
 ods output ParameterEstimates = _param_reg_&i.; 
 Run;


 
 Data _param_reg_&i.(keep=Candidate variable Estimate R2 RMSE Pvalue VIF Order Pvalue_Check VIF_Check);
 retain Candidate;
 set _param_reg_&i.;
 format Probt comma16.3 RMSE comma16.3 VarianceInflation comma16.3 variable $255.;

 rename Probt = Pvalue;
 rename VarianceInflation = VIF;

 Candidate = &&Candidate&i.;
 Order = 2;

 if variable = 'Intercept' then 
 do;
 Pvalue_Check = "Significant";
 Order = 1;
 end;

 else if 0 <= Probt <= 0.05 then Pvalue_Check = "Significant";
 else Pvalue_Check = "Failed";

 if VarianceInflation < 5 then VIF_Check = 'Passed';
 else VIF_Check = 'Failed';

 R2 = &&R&i.;
 RMSE = &&RMSE&i.;
 Run;


 Proc sort data=_param_reg_&i.;
 by Order;
 Run;


 %if &i. = 1 %then
 %do;
 Data &outdsn.;
 set _param_reg_&i.;
 format variable $255.;
 Run;
 %end;

 %else %do;
 Data &outdsn.;
 retain Candidate;
 format variable $255.;
 set &outdsn. _param_reg_&i.;
 Run;
 %end;

 %end;

 
/* Data &outdsn.;*/
/* set _param_reg_:;*/
/* format variable $255.;*/
/* Run;*/

%mend P_VIF_Test_PPNR;






















/************** Other Test (PPNR) -- Start **********************************************************************************************************************/
/************** Other Test (PPNR) -- Start **********************************************************************************************************************/
/************** Other Test (PPNR) -- Start **********************************************************************************************************************/



%macro OTHER_Test_PPNR(dsn1=, dsn2=, tar_var=, outdsn=);

 %do i=1 %to &max.;

 %put ******** MEVs: &&E&i.;
 %put ******** Loop: &i;

 ods output MiscStat=Normality DWTest=Autocorrelation ResetTest=Ramsey ARCHTest=ARCH ;
 Proc autoreg data=&dsn1.;
 model &tar_var. = &&E&i. / DW=1 dwprob LDW NORMAL RESET ARCHTEST=(qlm) ;
 Run;


 Data Normality;
 set Normality;
 format Normality_Flag $255.;
 if pval > 0.05 then Normality_Flag = "Passed";
 else Normality_Flag = "Failed";

 call symput("Normality_Flag", Normality_Flag);
 Run;


 
 Data Autocorrelation;
 set Autocorrelation;
 format Autocorr_Flag $255.;
 if ProbDW > 0.05 and ProbDWNeg > 0.05 then Autocorr_Flag = "Passed";
 else Autocorr_Flag = "Failed";

 call symput("Autocorr_Flag", Autocorr_Flag);
 Run;



 Data Ramsey;
 set Ramsey(where=(power=2));
 format Ramsey_Flag $255.;
 if ProbReset > 0.05 then Ramsey_Flag = "Passed";
 else Ramsey_Flag = "Failed";

 call symput("Ramsey_Flag", Ramsey_Flag);
 Run;



 Data Arch;
 set ARCH(where=(order=1));
 format Arch_Flag $255.;
 if ProbQ > 0.05 and ProbLM > 0.05 then Arch_Flag = "Passed";
 else Arch_Flag = "Failed";

 call symput("Arch_Flag", Arch_Flag);
 Run;




 %if &i. = 1 %then
 %do;
 Data &outdsn.;
 set &dsn2.;

 if candidate = &&Candidate&i. then
 do;
 Normality_Flag = "&Normality_Flag.";
 Autocorr_Flag = "&Autocorr_Flag.";
 Ramsey_Flag = "&Ramsey_Flag.";
 Arch_Flag = "&Arch_Flag.";
 end;
 Run;
 %end;


 %if &i. > 1 %then
 %do;
 Data &outdsn.;
 set &outdsn.;

 if candidate = &&Candidate&i. then
 do;
 Normality_Flag = "&Normality_Flag.";
 Autocorr_Flag = "&Autocorr_Flag.";
 Ramsey_Flag = "&Ramsey_Flag.";
 Arch_Flag = "&Arch_Flag.";
 end;
 Run;
 %end;

 %end;

%mend OTHER_Test_PPNR;
/************** Exhausitive Search for Account Level (Prepay) -- Start **********************************************************************************************************************/
/************** Exhausitive Search for Account Level (Prepay) -- Start **********************************************************************************************************************/
/************** Exhausitive Search for Account Level (Prepay) -- Start **********************************************************************************************************************/


%macro Exhau_Search_Prepay(dsn=, tempdsn=, var_list_nochg=, outdsn=, beg_num=, end_num=, combdsn=, targ_var=, targ_bal=, actual_targ_rate=,);
 
 %do i=&beg_num. %to &end_num.;

 data _null_;
 set &combdsn.;
 if _n_ = &i. then CALL SYMPUT ('MEVs', Var_Comb); 
 run;

 %global &MEVs.;
 %put ******** MEVs: &MEVs.;
 %put ******** Loop: &i;

 Proc logistic Data=&dsn.;
 model &targ_var. / &targ_bal. = &var_list_nochg. &MEVs. / link=logit;
 output out=Prediction(keep=ACCOUNT FILE_DATE &actual_targ_rate. Pred) Predicted=Pred;
 ods output Association=Train_C ;
 Run;


 Data Prediction;
 set Prediction;
 Resid = &actual_targ_rate. - Pred;
 Square_Error = Resid * Resid;
 Run;


 Proc SQL;
 select
 count(*) as Total_Obs,
 sum(Square_Error) as Sum_SQE,
 calculated Sum_SQE / calculated Total_Obs as MSE,
 sqrt(calculated MSE) into :Obs, :Sum_SQE, :MSE, :RMSE
 from
 Prediction;
 Quit;




 Data Train_C;
 set Train_C nobs=nobs;
 if _n_ = nobs then output;
 Run;

 Data Train_C;
 set Train_C ;
 call symput("ROC", CValue2);
 Run;




 %if &i. - &beg_num. + 1 = 1 %then
 %do;

 Data &outdsn.;
 set &tempdsn.;
 informat Var_Chg $10000. Var_NoChg $10000.;

 Var_Chg = "&MEVs.";
 Var_NoChg = "&var_list_nochg.";
 ROC = &ROC.;
 Candidate = &i.;
 RMSE = &RMSE.;
 Run;

 %end;

 %else %do;
 Data _Temp_2;
 set &tempdsn.;
 informat Var_Chg $10000. Var_NoChg $10000.;

 Var_Chg = "&MEVs.";
 Var_NoChg = "&var_list_nochg.";
 ROC = &ROC.;
 Candidate = &i.;
 RMSE = &RMSE.;
 Run;

 Data &outdsn.;
 retain Candidate;
 informat Var_Chg $10000. Var_NoChg $10000.;
 set &outdsn. _Temp_2;
 Run;

/* Proc append base=&outdsn. data=_Temp_2;*/
/* run;*/
 %end; 

 %end;
%mend Exhau_Search_Prepay;

























/************** P-value and VIF Test (Prepay) -- Start **********************************************************************************************************************/
/************** P-value and VIF Test (Prepay) -- Start **********************************************************************************************************************/
/************** P-value and VIF Test (Prepay) -- Start **********************************************************************************************************************/


%macro P_VIF_Test_Prepay(dsn=, test1_dsn=, candidate=, outdsn=, targ_var=, targ_bal=, rep_subj=, beg_num=, end_num=, var_list_nochg=,);

 %do i=&beg_num. %to &end_num.;

 data _null_;
 set &test1_dsn.;
 if _n_ = &i. then CALL SYMPUT ('MEVs', Var_Chg);
 if _n_ = &i. then CALL SYMPUT ('Candi', Candidate);
 if _n_ = &i. then CALL SYMPUT ('ROC', ROC);
 if _n_ = &i. then CALL SYMPUT ('RMSE', RMSE);
 run;

/* %global &MEVs. &Candi.;*/
 %put ******** MEVs: &MEVs.;
 %put ******** Loop: &i;

 Proc GENMOD Data=&dsn. namelen=50;
 class &rep_subj.;
 &i. :model &targ_var. / &targ_bal. = &var_list_nochg. &MEVs. / link=logit;
 repeated subject=&rep_subj.;
 ods output GEEEmpPEst=_parameters_&i.;
 Run;

 Proc Reg Data=&dsn. ;
 model &targ_var. = &var_list_nochg. &MEVs. / vif;
 ods output ParameterEstimates = _param_reg_&i.; 
 Run;


 
 Data _parameters_&i.(keep=Candidate Parm Estimate ROC RMSE Pvalue Order Pvalue_Check);
 set _parameters_&i.;
 format ProbZ comma16.6 RMSE comma16.6 Parm $255.;

 rename ProbZ = Pvalue;
 Candidate = &Candi.;
 Order = 2;

 if Parm = 'Intercept' then 
 do;
 Pvalue_Check = "Significant";
 Order = 1;
 end;

 else if 0 <= ProbZ <= 0.05 then Pvalue_Check = "Significant";
 else Pvalue_Check = "Failed";

 ROC = &ROC.;
 RMSE = &RMSE.;
 Run;



 Data _param_reg_&i.(keep=Candidate Variable VarianceInflation VIF_Check);
 set _param_reg_&i.;
 format VarianceInflation comma16.6 variable $255.;

 Candidate = &Candi.;
 if VarianceInflation < 5 then VIF_Check = 'Passed';
 else VIF_Check = 'Failed';
 Run;




 Proc SQL;
 create table _parameters_&i. as
 select
 a.Candidate,
 a.Order,
 a.Parm,
 a.Estimate,
 a.ROC,
 a.RMSE,
 a.Pvalue,
 b.VarianceInflation,
 a.Pvalue_Check,
 b.VIF_Check
 from
 _parameters_&i. as a
 left join
 _param_reg_&i. as b
 on
 a.Parm = b.Variable;
 Run;



 Proc sort data=_parameters_&i.;
 by Order;
 Run;


 %if &i. - &beg_num. + 1 = 1 %then
 %do;
 Data &outdsn.;
 format Parm $255.;
 set _parameters_&i.;
 Run;
 %end;

 %else %do;
 Data &outdsn.;
 retain Candidate;
 format Parm $255.;
 set &outdsn. _parameters_&i.;
 Run;
 %end;

 %end;

/* Data &outdsn.;*/
/* set _parameters_:;*/
/* Run;*/

%mend P_VIF_Test_Prepay;
View Michael’s profileMichael Jasper
Michael Jasper  10:57 AM
👏
👍
😊



/************** Outlier Check -- Start **********************************************************************************************************************/
/************** Outlier Check -- Start **********************************************************************************************************************/
/************** Outlier Check -- Start **********************************************************************************************************************/


%MACRO Outlier_Analysis(indsn=, Seg=, RateType=, Var=, Filter=, Column=, out=);

 Data _Temp_Data_1;
 set &indsn.;
 where latest_prod_const = &Seg. and rate_type_updated2 = &RateType. and &Var. = &Filter. and &Column. > 0;
 Run;


 ods select None;
 Proc univariate data=_Temp_Data_1;
 Var &Column.;
 output out=&out. pctlpts=5 10 25 50 75 90 95 100 pctlpre=&Column.
 pctlname=_P5 _P10 _P25 _P50 _P75 _P90 _P95 _P100;
 Run;
 ods select all;


 Data &out.;
 retain &Var. ;
 set &out.;
 &Var. = &Filter.;
 Run;

%mend Outlier_Analysis;







%Macro Outlier_Analysis_Automation(start1=, end1=, start2=, end2=, indsn=, outdsn=, Seg=, RateType=, Var=, 
 Column=, out=);

 proc delete data=&outdsn.; run;

 %if &start2. > 0 and &end2. > 0 %then
 %do;
 %do i = &start1. %to &end1.;
 %do j = &start2. %to &end2.; 
 %Outlier_Analysis(indsn=&indsn., Seg=&Seg., RateType=&RateType., Var=&Var., Filter=(&i.*100 + &j.), 
 Column=&Column., out=&out.);

 Proc append base=&outdsn. data=&out.; run;
 %put ********* &i. &j. ********************; 

 %end;
 %end;
 %end;

 %else %do;
 %do i= &start1. %to &end1.;
 %Outlier_Analysis(indsn=&indsn., Seg=&Seg., RateType=&RateType., Var=&Var., Filter=&i., 
 Column=&Column., out=&out.);

 Proc append base=&outdsn. data=&out.; run;
 %put ********* &i. *****************;
 %end;
 %end;

 Data &outdsn.;
 set &outdsn.;
 format &Column._P5 &Column._P10 &Column._P25 &Column._P50 &Column._P75 
 &Column._P90 &Column._P95 &Column._P100 comma16. ;
 Run;

%mend Outlier_Analysis_Automation;





















/************** Missing Value Check -- Start **********************************************************************************************************************/
/************** Missing Value Check -- Start **********************************************************************************************************************/
/************** Missing Value Check -- Start **********************************************************************************************************************/


%Macro Missing_Check(indsn=, outdsn=,);

 * create formats for missing;
 proc format;
 value $missfmt ' ' = "Missing" other = "Not_Missing";
 value nmissfmt low-high ="Not_Missing" other="Missing";
 run;

 * turn off output and capture the one way freq table TEMP dataset ; 
 ods select none;
 ods table onewayfreqs=temp;

 proc freq data=&indsn.;
 table _all_ / missing;
 format _numeric_ nmissfmt. _character_ $missfmt.;
 run;

 * turn outputs back on ;
 ods select all;

 * Collapse to one observation per variable ;
 data &outdsn. ;
 length name $32 missing not_missing total 8 ;
 set temp;
 by table notsorted ;
 if first.table then call missing(of missing not_missing);
 name = substr(table,7);
 if vvaluex(name)='Missing' then missing=frequency;
 else not_missing=frequency;
 retain missing not_missing;
 if last.table then do;
 missing=sum(0,missing);
 not_missing=sum(0,not_missing);
 total=sum(missing,not_missing);
 percent = divide(missing,total);
 output;
 end;
 keep name missing not_missing total percent;
 run;



 Data &outdsn.;
 set &outdsn.;
 format missing comma16. not_missing comma16. total comma16. percent percent10.;
 Run;

%Mend Missing_Check;



