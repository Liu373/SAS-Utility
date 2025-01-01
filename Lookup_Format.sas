
************ Two ways to create Lookup Table in SAS ******************************************************;

********* The 1st way is to mannually create the table *********************;
Proc format;
  value $brr_pd_pct
    '0'   = 0.0000058
    '1A'  = 0.00012
    '2B'  = 0.00023
    other = 0.0234;

  value $brr_pd_dt_pct
    '0'   = 0.00023
    '1A'  = 0.00034
    '2B'  = 0.00045
    other = 0.0334;
Quit;




***************************************** The 2nd way is to leverage the existing table *****************************************************;
****** Your dataset needs to have 3 columns: 1st for rating, 2nd for value that you want to refer and 3rd is the format name ****************;
Data ct;
  set pd_mult_perm;
  retain fmtname "$pd_mult_perm";
  output;
Run;

proc format library=work  cntline=ct;
Run;





************* Lookup your value *****************************;
Proc SQL;
  create table abc as
  select
    a.*,
    case when
      upcase(strip(b.scenario_type)) = "BASE" and upcase(strip(a.ratetype)) in ("FIXED", "FLOAT") then
      input(put(a.brr,  $pd_mult_perm.), best32.)
    when
      upcase(strip(b.scenario_type)) NE "BASE" and upcase(strip(a.ratetype)) in ("FIXED", "FLOAT") then
      input(put(a.brr,  $pd_mult_dt_perm.), best32.)
    else
      1
    end as pd_multiplier

  from
    table1 as a
  left join
    table2 as b
  on
    a.id = b.id;
Run;
      



************* Check your Format Value *****************************;
Data _null_;
  format_value = put("1A", $pd_mult_perm.);
  put format_value = ;
Run;










