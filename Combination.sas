
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



