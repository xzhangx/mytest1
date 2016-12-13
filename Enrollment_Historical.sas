
*****libname EDW oracle user=xxxxx orapw=xxxxxx path='dsprod01' SCHEMA='EDW'******;
%include 'c:\sasconns\edwlib.inc'; /*assigns libname EDW - userid and password embedded in file*/
libname stu 'X:\OIR DATA LIBRARY\enrollment';
libname temp 'X:\OIR DATA LIBRARY\enrollment\temp';
libname coh 'X:\OIR DATA LIBRARY\Cohort';

***This is only to find snapshot keys for macros - can be deleted later*****;
/*proc sql;
	create table keys as select
	distinct reg_snapshot_key,
			term_cd
		from edw.t_rs_time where reg_snapshot_cd='CN' and term_cd in (;
quit;

proc print data=keys noobs;
	var term_cd reg_snapshot_key;
	run;

proc freq data=edw.t_rs_time;
table term_cd*reg_snapshot_key/norow nocol nopercent missing;
where term_cd >='220068' and reg_snapshot_cd='CN' ;
run;*/


/********************************************************************************/
***PULL BASE POPULATION FALL 2004-FALL 2014*****;
proc sql;
      create table UIC_BASE as
      select 
	         p.edw_pers_id,
			 p.uin,
		     p.pers_confidentiality_ind as confid_ind,
		     p.birth_dt,
			 p.age,
			 p.pers_citzn_type_cd as citizen_type,
		     p.pers_citzn_type_desc as citizen_desc,
			 p.pers_citzn_type_group as citizen_group,
			 p.ipeds_race_eth_cd,
			 p.ipeds_race_eth_desc,
			 p.ipeds_race_eth_catgry,
			 p.ipeds_race_eth_catgry_desc,
		     p.race_eth_rpt_cd as ipeds_re_catgry_cd,
		     p.race_eth_rpt_desc as ipeds_re_catgry_desc,
		     p.hispanic_eth_ind,
		     p.aian_race_ind,
		     p.asian_race_ind,
		     p.black_race_ind,
		     p.nhpi_race_ind,
		     p.white_race_ind,
		     p.mult_race_ind,
		     p.sex_cd,
		     p.sex_desc,
             c.reg_snapshot_key, 
             c.reg_snapshot_cd, 
             c.term_cd, 
             a.student_admit_term_cd as admit_term, 
			 a.student_res_cd as res_code,
			 a.student_res_desc as res_desc,
			 a.student_res_group as res_group,
			 a.student_type_cd as type_code,
			 a.student_type_desc as type_desc,
             a.student_level_cd as level_code, 
             a.student_level_desc as level_desc, 
             a.coll_cd as college_code, 
             a.acad_coll_name as college_name, 
             a.admin_coll_cd as admin_college, 
             a.admin_coll_name as admin_name, 
             a.dept_cd as dept_code, 
             a.student_dept_name as dept_name, 
             a.student_acad_pgm_cd as acad_program,
			 a.student_acad_pgm_name as acad_program_name,
             a.student_curr_1_major_cd as curr1_major, 
             a.student_curr_1_major_name as curr1_name,
			 a.student_curr_1_major_cip_cd as curr1_major_cip,
             a.student_curr_1_deg_cd as deg_cd, 
			 a.student_curr_1_deg_name as deg_name,
			 a.student_curr_1_major_2_cd as curr1_major2,
			 a.student_curr_1_major_2_cip_cd as curr1_major2_cip,
			a.student_curr_1_major_2_name as major2_name,
			a.STUDENT_curr_2_ACAD_PGM_CD as curr2_program,
			a.STUDENT_curr_2_acad_pgm_name as curr2_name,
			a.student_curr_2_coll_cd as curr2_coll_cd,
			a.student_curr_2_coll_name as curr2_coll_name,
			a.student_curr_2_deg_cd as curr2_deg_cd,
			a.student_curr_2_deg_name as curr2_deg_name,
			a.student_curr_2_level_cd as curr2_level_cd,
             a.level_deg_group,
			 a.calc_cls_cd,
             a.calc_cls_desc,
			 a.student_educ_goal_cd as educ_goal,
             a.student_educ_goal_desc as educ_name,
			 a.student_fee_asmt_rt_cd as fee_rate_code,
			 a.student_fee_asmt_rt_desc as fee_rate_desc,
             b.student_reg_ind, 
             b.ipeds_time_status_cd, 
             b.student_tot_reg_credit_hour as credit_hrs,
             1 as count
      from edw.T_rs_student a, 
           edw.T_rs_student_reg b, 
           edw.T_rs_time c,
		   edw.T_rs_pers p
      where a.edw_pers_id = b.edw_pers_id = p.edw_pers_id
            and p.reg_snapshot_key = a.reg_snapshot_key = b.reg_snapshot_key = c.reg_snapshot_key
            and a.student_status_desc like 'Active%'
            and b.student_reg_ind = 'Y'
            and c.term_cd in ('220048','220058','220068','220078','220088','220098',
		                      '220108','220118','220128','220138','220148',
                              '220041','220051','220061','220071','220081','220091',
		                      '220101','220111','220121','220131','220141',  
                              '220045','220055','220065','220075','220085','220095',
		                      '220105','220115','220125','220135','220145',
                              '220089','220099' )
		    and c.reg_snapshot_cd in ('CN','CE');
			;
quit;  



****MAKE MODIFICATIONS TO EDW VARS*****;
data UIC_ENROLLMENT;
   set UIC_BASE;
  	length type $30.;
/* EDIT MISSING COLLEGE CODES */
   if college_code = '' 
		then do;
			college_code = admin_college;
			college_name = admin_name;
			end;  
/* PLACE GLOBAL CAMPUS TERMS INTO "REGULAR" TERM */ 
   if term_cd = '220089' then term_cd = '220088';
   if term_cd = '220099' then term_cd = '220098';

/* SEPARATE CONTRACT AND CONTINUING ED */
   /* GB - 'Extension' */
   /* GN - 'External Education' later renamed 'School of Continuing Studies' */
   if reg_snapshot_cd = 'CN'
      then do;
         order = 1;
		 if substr(acad_program,2,1) = '1' or college_code in ('GB','GN')
		 then delete;
   end;
   if reg_snapshot_cd = 'CE'
      then do;
	  	 continuing_ed='Y';
         order = 2;
         if substr(acad_program,2,1) = '1' or college_code in ('GB','GN');
         if level_deg_group = 'NA - Non-credit' then delete;
   		end;
		else continuing_ed='N';
   if level_deg_group = 'NA - Non-credit' then delete;

/*Add in Indicators*/
    if strip(reverse(acad_program))=: 'U' then online_program='Y';
	else online_program='N';

/* SET HISTORTICAL RACE/ETHNICITY TO COINCIDE WITH PRESENT CODE */
   if term_cd >= '220108'
		then do;
			race_cd = ipeds_re_catgry_cd;
			race_desc = ipeds_re_catgry_desc;
			end;
		else do;
			race_cd = ipeds_race_eth_catgry;
			race_desc = ipeds_race_eth_catgry_desc;
			if race_cd in ('6','')
				then do;
					race_cd = '6';
					race_desc = 'Unknown';
					end;
   end;

/* CREATE GENDER FIELD */
	if sex_cd = 'F' 
		then gender = 'F';
		else gender = 'M';

/* CREATE CAMPUS REPORTING LEVELS */
   if level_code in ('2U','2X') then
		level_derived = '1Undergraduate';
   if level_code in ('2G','2Y') then
		level_derived = '2Graduate';
	if (deg_cd = 'DNP' and term_cd >= '220148') or (level_code ='2P') then
		level_derived = '3Professional';
   if reg_snapshot_cd = 'CE' then
		level_derived = '4ContEd/Cntrct';
	
   
/* LEVELS FOR IPEDS/IBHE */
   if level_code in ('2U','2X') then IPEDS_level = '1Undergraduate';	
   if level_code in ('2G','2Y') then IPEDS_level = '2Graduate';
		
   if level_code in ('2P') then IPEDS_level = '3Professional';
/* MOVE LEVELS BASED ON TERM AND DEGREE */
   if deg_cd = 'DPT' and term_cd < '220098' 
      then IPEDS_level = '2Graduate'; 	
   if deg_cd = 'ADV' 
      then IPEDS_level = '2Graduate'; 	
   if deg_cd = 'DNP' and term_cd >= '220148' 
      then IPEDS_level = '3Professional';
/* IPEDS FULL/PART BASED ON CREDIT HOURS */
   if ipeds_level in ('1Undergraduate','3Professional')
      then do;
         if credit_hrs >= 12
         then fulltime = 'Full-Time';
         else fulltime = 'Part-Time';
   		end;
      else if ipeds_level='2Graduate' then do;
         if credit_hrs >= 9
         then fulltime = 'Full-Time';
         else fulltime = 'Part-Time';
   		end;	

   ******Add in Newcol Var*****;
   if level_derived ='2Graduate' then newcol = 'Grad';
   else newcol = college_name;
	if college_code in ('FV','FZ','GA','GC','GD','GE') and level_derived ^='2Graduate' then do;
		newcol = 'Medicine'; 
		college_medicine='Y';
		end;

		else do;
		newcol = college_name;
		college_medicine='N';
		end;

   ******TYPE CODES*******;

	if level_code = '2U' and type_code = 'F' then do;
        	type = '1New Freshmen'; 
			type_order=1;
			new_fresh='Y'; 
			end;
	else if level_code = '2U' and type_code in ('T','X') then do;
        	type = '2New Transfer'; 
			type_order=2;
			new_transfer='Y'; 
			end;
	if type_code in ('C','K') then do;
        	type = '9Continuing'; 
			type_order= 9; 
			end;
	if level_code in ('2X','2Y') and type_code not in ('C','K') then do ;
        	type = '4New Nondegree';  
			type_order = 4; 
			new_nondegree='Y';
			end;
	if type_code = 'R' then do;
        	type = '3Readmit'; 
			type_order = 3; end;
	if type_code in ('G','T','Y') and level_code in ('2G') then do;
        	type = '7New Graduate'; 
			type_order = 7; 
			new_grad='Y'; end;
	if level_code = '2P' and type_code ^='C' then do;
        	type = '8New Professional'; 
			type_order = 8; end;

*******AGE GROUPING******;
	length age_group $10.;
	if age = . then age_group = 'unknown';
	if age LT 23  and age ^=. then age_group = '<23';
	if age GT 22 and age LT 25 then age_group = '23-24';
	if age GT 24 and age LT 30 then age_group = '25-29';
	if age GE 30  and age ^=. then age_group = '30+';

proc sort;
	by term_cd edw_pers_id order;

run;
proc sort data=UIC_ENROLLMENT out=stu.UIC_ENROLLMENT nodupkey;
	by term_cd edw_pers_id;
run;


***ADD NEW VARS*****;

****CREATE AP CREDITS FIELD******;  ***this gets added in with freshmen specific vars below***;
proc sql;
      create table stu.apcredits as
      select *, sum (crs_credit_hour) as ap_credits
      from edw.t_student_overall_crs_detl 
      where crs_credit_type_cd ='TB'
      and tfer_inst_name = 'Advanced Placement Tests'
      and campus_cd = '200'
      and CRS_LEVEL_CD = '2U'
      group by edw_pers_id;
quit;

***create student athlete indicator***;
proc sql;
	create table stu.athlete as 
	select distinct a.edw_pers_id,
					a.term_cd,
					'Y' as athlete
from stu.UIC_enrollment a
left join EDW.T_STUDENT_ATHL_SPORT b
on a.edw_pers_id=b.edw_pers_id
where b.STUDENT_ACTV_CD  Is Not Null
and a.Term_cd=b.term_cd;
quit;

****add imputed credits and athlete indicator created above*****;
proc sql;
	create table stu.imp as select distinct
	a.edw_pers_id,
	a.term_cd,
	sum(b.crn_imputed_hour) as ttl_imp
FROM stu.UIC_ENROLLMENT a
left JOIN edw.t_rs_student_crs_info b
ON a.EDW_PERS_ID = b.EDW_PERS_ID
and a.reg_snapshot_key=b.reg_snapshot_key
group by a.edw_pers_id;
quit;

****Add new fields***;

proc sql;
	create table enroll_hist as select
	a.*,
	c.ttl_imp,
	case 
		when b.athlete='Y' then 'Y'
		else 'N'
	end as athlete
from stu.UIC_ENROLLMENT a
left join stu.imp c
on a.edw_pers_id=c.edw_pers_id
and a.term_cd=c.term_cd
left join stu.athlete b
on a.edw_pers_id=b.edw_pers_id
and a.term_cd=b.term_cd;
quit;

data stu.enroll_hist;
	set enroll_hist;
run;

proc freq data=stu.enroll_hist;
	table term_cd;
run;

***CREATE TEMP FALL SNAPS - BASE FILES*****;

****pull out separate files by term *****;
%macro terms (file,term);

data stu.temp&file;
	set stu.enroll_hist /*stu.base2*/;
	where term_cd=&term;
run;

%mend;
%terms (fall04,'220048');
%terms (fall05,'220058');
%terms (fall06,'220068');
%terms (fall07,'220078');
%terms (fall08,'220088');
%terms (fall09,'220098');
%terms (fall10,'220108');
%terms (fall11,'220118');
%terms (fall12,'220128');
%terms (fall13,'220138');
%terms (fall14,'220148');
%terms (spring05,'220051');
%terms (spring06,'220061');
%terms (spring07,'220071');
%terms (spring08,'220081');
%terms (spring09,'220091');
%terms (spring10,'220101');
%terms (spring11,'220111');
%terms (spring12,'220121');
%terms (spring13,'220131');
%terms (spring14,'220141');
%terms (summer05,'220055');
%terms (summer06,'220065');
%terms (summer07,'220075');
%terms (summer08,'220085');
%terms (summer09,'220095');
%terms (summer10,'220105');
%terms (summer11,'220115')
%terms (summer12,'220125');
%terms (summer13,'220135');
%terms (summer14,'220145');

****PULL FIELDS FOR NEW UG STUDENTS*****;
%macro newfall (file,term,snap);

proc sql;
	create table fresh&file as
	select distinct a.*,
		/*b.max_act_composite_score as act_composite,
		b.max_act_engl_score as act_english,
		b.max_act_math_score as act_math,
		b.max_act_reading_score as act_reading,
		b.max_act_science_reason_score as act_science,
		c.ADM_STD_HS_PCT as hspr,*/
		e.ADM_REVW_HS_GPA as hsgpa,
		c.adm_std_hs_grad_dt,
		d.ap_credits
	from stu.temp&file a 
	left join (select * from edw.T_RS_MAX_TEST_SCORE where REG_SNAPSHOT_Key =&snap 
	and campus_cd = '200') b
		on a.edw_pers_id = b.edw_pers_id
	left join (select * from EDW.T_RS_ADM_STD_HS_HIST where REG_SNAPSHOT_Key =&snap
	and campus_cd = '200') c
		on a.edw_pers_id = c.edw_pers_id
	left join (select * from EDW.V_ADM_STD_HS_HIST where ADM_STD_HS_CUR_INFO_IND = 'Y'
		and ADM_STD_HS_CAMPUS_CD = '200') e
		on a.edw_pers_id = e.edw_pers_id
	left join stu.apcredits d
		on a.edw_pers_id = d.edw_pers_id
	where a.type_code = 'F' ;
quit;

proc sql;
	Create table trans&file as
	Select distinct a.*,
	c.level_gpa_hour as T_gpa_hours ,
	c.level_gpa_qual_pt as T_gpa_qual,
	c.level_gpa as T_gpa
	/*b.PRIOR_CUM_DEG_TFER_GPA as Admit_T_gpa,
	b.PRIOR_CUM_DEG_TFER_HOURS as Admit_T_hrs*/
	from stu.temp&file a 
	Left join 
		(select * from edw.t_rs_student_ah_level_gpa
			Where gpa_level_cd = '2U' and campus_cd = '200' 
				and level_gpa_type_ind = 'T') C
		On a.edw_pers_id = C.edw_pers_id
		and a.reg_snapshot_key = c.reg_snapshot_key
	left join EDW.V_ADM_PRIOR_CUM_DEG_HIST b
    on  a.edw_pers_id = b.edw_pers_id
	where a.type_code='T' 
	and b.PRIOR_CUM_DEG_CUR_INFO_IND = 'Y' 
	and b.PRIOR_CUM_DEG_TFER_GPA ne . 
	;

quit;

proc sort data=fresh&file out=&file;
BY EDW_PERS_ID hsgpa;
RUN;

DATA fresh&file;
	set &file;
	BY EDW_PERS_ID hsgpa;
	if last.edw_pers_id;
run;

proc sort data=trans&file out=&file;
BY EDW_PERS_ID t_gpa;
RUN;

DATA trans&file;
	set &file;
	BY EDW_PERS_ID t_gpa;
	if last.edw_pers_id;
run;

data stu.fresh&file;
	set fresh&file;
run;

data stu.trans&file;
	set trans&file;
run;


%mend newfall;

%newfall (fall04,'220048',12);
%newfall (fall05,'220058',106);
%newfall (fall06,'220068',210);
%newfall (fall07,'220078',281);
%newfall (fall08,'220088',385);
%newfall (fall09,'220098',448);
%newfall (fall10,'220108',569);
%newfall (fall11,'220118',631);
%newfall (fall12,'220128',687);
%newfall (fall13,'220138',755);
%newfall (fall14,'220148',823);


***check for dups****;
proc sql;
	create table dups as
	select edw_pers_id
	from stu.transfall04
	group by edw_pers_id having count(*) >1;
quit;

proc print data=dups;
run;

proc print data=stu.transfall04;
	where edw_pers_id in (12081,14284,14335,14523,15616,18800);
run;

****ADD IN OLD FIELDS FROM SNAPS****;
 ***FALL TERMS FIRST****;

%macro vars (file,term);

***add fields from existing files****;
proc sql; 
create table &file as
select a.*,
		b.class_revised,
		b.classrev_desc,
		b.act_composite,
		b.act_english,
		b.act_math,
		b.act_reading,
		b.act_science,
		b.hspr,
		b.highsch_code,
		b.highsch_name,
		b.highsch_type,
		b.math_placement,
		b.comp_placement,
		b.chem_placement,
		b.transfercoll_code,
		b.transfercoll_name,
		b.transfercoll_type,
		b.chicago_city_coll as chic_city_coll_trans, /*2004 2005 2006 only;*/
		/*b.chic_city_coll_trans,*/
		b.gppa,
		b.gppa_program,
		/*b.pap,*/
		b.honors_college as hc, /*2004-2008*/
		b.permres_city,
		b.permres_il_county,
		/*b.permres_state,*/
		b.permres_state_name,
		b.permres_zipcode,

		/**2008+*
		b.highsch_state,
		b.transfercoll_state,*/
		b.permres_foreign_cntry as ADDR_NATION_NAME

		/*2009+*/
		/*b.math_placement_desc,
		b.comp_placement_desc,
		b.chem_placement_desc,*/
		/*b.class,
		b.deg_level_cd,
		b.deg_level_desc
		/*b.hc,*/
		/*b.permres_il_county_cd,
		/*b.ADDR_NATION_CD,
		b.ADDR_NATION_NAME,
		b.Country_of_Citizenship,*/
		/*b.geo_derived
		
		/*2010+
		b.order_class
	
		/*2012+
		b.paph

		/*2014+
		b.fgen*/
	
	from stu.temp&file a
	left join stu.&file b
	on a.edw_pers_id=b.edw_pers_id;
quit;

proc sql; 
create table new&file as
	select a.*,
		c.hsgpa,
		c.adm_std_hs_grad_dt,
		c.ap_credits,
		d.T_gpa_hours,
		d.T_gpa_qual,
		d.T_gpa
	from &file a
	left join stu.fresh&file c
	on a.edw_pers_id=c.edw_pers_id
	left join stu.trans&file d
	on a.edw_pers_id=d.edw_pers_id
	;
quit;

data stu.&file; 
	set new&file;
run;

%mend vars;

%vars (fall04,'220048');
%vars (fall05,'220058');

%vars (fall06,'220068');
%vars (fall07,'220078');
%vars (fall08,'220088');
%vars (fall09,'220098');
%vars (fall10,'220108');
%vars (fall11,'220118');
%vars (fall12,'220128');
%vars (fall13,'220138');
%vars (fall14,'220148');

%vars (spring09,'220091');
%vars (spring10,'220101');
%vars (spring11,'220111');
%vars (spring12,'220121');
%vars (spring13,'220131');
%vars (spring14,'220141');

%vars (summer09,'220095');
%vars (summer10,'220105');
%vars (summer11,'220115')
%vars (summer12,'220125');
%vars (summer13,'220135');
%vars (summer14,'220145');


*****Add in flags****;
%macro add (file,term);

/*data new&file;
	set stu.&file;

	if type_code='F' then do;
		if ap_credits >0 then ap_flag=1;
		else ap_flag=0;
	end;
	else if type_code^='F' then do;
		ap_flag=.;
		ap_credits=.;
	end;

	if highsch_type = 'Chicago Public' then CPS=1;
	else CPS=0;

	if race_desc in ('AIAN' 'Black/African American', 'Hispanic', 'NHPI') then URM=1;
	else URM=0;

run;*/

data new&file;
	set stu.&file;
	drop ap_flag ap_credits highsch_type CPS;
run;

data stu.&file;
	set new&file;
run;

%mend;


/*%add (fall04,'220048');
%add (fall05,'220058');
%add (fall06,'220068');
%add (fall07,'220078');
%add (fall08,'220088');
%add (fall09,'220098');
%add (fall10,'220108');
%add (fall11,'220118');
%add (fall12,'220128');
%add (fall13,'220138');
%add (fall14,'220148');

%add (spring09,'220091');*/
%add (spring10,'220101');
%add (spring11,'220111');
%add (spring12,'220121');
%add (spring13,'220131');
%add (spring14,'220141');
%add (summer09,'220095');
%add (summer10,'220105');
%add (summer11,'220115')
%add (summer12,'220125');
%add (summer13,'220135');
%add (summer14,'220145');


	/*

*AP FLAG*
a.ap_credits,
case when ap_credits >0 then 1 else 0 end as ap_flag,

*CPS FLAG*
a.highsch_type,
case when highsch_type = 'Chicago Public' then 1 else 0 end as CPS,

*URM FLAG* 
a.race_desc,
case when race_desc in ('AIAN' 'Black/African American', 'Hispanic', 'NHPI') then 1 else 0 end as URM,

*RANK* 
Rank is done by type code T or F so I am unsure how this will integrate into your process
/*create quintiles*/
PROC SORT DATA = cohort&year.temp;
      BY TYPE_CODE;
RUN;

proc rank data = cohort&year.temp
     groups=5
     out=cohort&year.temp2;
var ACT_COMPOSITE T_GPA HSGPA;
ranks ACT_COMP_rank T_GPA_RANK HS_GPA_RANK ;
BY TYPE_CODE;
run;

*URM*;

%macro add (file,year);

proc sql;
	create table temp&file as
	select a.*,
			b.ACT_COMP_rank,
			B.T_GPA_RANK,
			b.HS_GPA_RANK
	from stu.&file a
	left join coh.Cohort&year b
	on a.edw_pers_id=b.edw_pers_id;
quit;

data stu.&file;
	set temp&file;
run;

%mend;

%add (fall04,2004);
%add (fall05,2005);
%add (fall06,2006);
%add (fall07,2007);
%add (fall08,2008);
%add (fall09,2009);
%add (fall10,2010);
%add (fall11,2011);
%add (fall12,2012);
%add (fall13,2013);
%add (fall14,2014);

%macro correct (file,term);

data temp_&file;
	set stu.&file;
	drop ttl_imp;
run;

proc sql;

create table temp1_Z as select distinct         /* modified by Henry and Xiaotong. 08262015 by removing a.* */  
	a.edw_pers_id,
	sum(b.crn_imputed_hour) as ttl_imp
FROM temp_&file a
left JOIN edw.t_rs_student_crs_info b
ON a.EDW_PERS_ID = b.EDW_PERS_ID
and a.reg_snapshot_key=b.reg_snapshot_key
group by a.edw_pers_id;


create table temp.&file as select distinct              /* modified by Henry and Xiaotong. 08262015 by removing a.* */        
	a.*, b.ttl_imp
FROM temp_&file a
inner JOIN temp1_Z b
ON a.EDW_PERS_ID = b.EDW_PERS_ID
;
quit;

%mend;

%macro test (file,term);

data temp&file;
	set stu.&file  (drop=fulltime);

	/* IPEDS FULL/PART BASED ON CREDIT HOURS */
   if ipeds_level in ('1Undergraduate','3Professional')
      then do;
         if credit_hrs >= 12
         then fulltime = 'F';
         else fulltime = 'P';
   		end;
      else if ipeds_level='2Graduate' then do;
         if credit_hrs >= 9
         then fulltime = 'F';
         else fulltime = 'P';
   		end;

run;

data stu.&file;
	set temp&file;
run;


%mend;	

/*%test (fall04,'220048');*/
%test (fall05,'220058');
%test (fall06,'220068');
%test (fall07,'220078');
%test (fall08,'220088');
%test (fall09,'220098');
%test (fall10,'220108');
%test (fall11,'220118');
%test (fall12,'220128');
%test (fall13,'220138');
%test (fall14,'220148');
%test (spring08,'220081');
%test (spring09,'220091');
%test (spring10,'220101');
%test (spring11,'220111');
%test (spring12,'220121');
%test (spring13,'220131');
%test (spring14,'220141');
%test (summer08,'220085');
%test (summer09,'220095');
%test (summer10,'220105');
%test (summer11,'220115')
%test (summer12,'220125');
%test (summer13,'220135');
%test (summer14,'220145');


proc freq data=temp.fall13;
	table ipeds_level*ttl_imp/norow nocol nopercent;
run;

/* added by xz for testing.  12/13/2016 */
