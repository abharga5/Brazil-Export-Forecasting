data brazil;
input Count $ Quarter $ Exports;

/* Exports are measured in millions of currency units.
   Data is quarterly from 1995-2018
*/
cards;
9	1995Q1	10401.00
10	1995Q2	12493.41
11	1995Q3	14259.50
12	1995Q4	14053.16
13	1996Q1	12305.88
14	1996Q2	14576.31
15	1996Q3	15560.48
16	1996Q4	15084.72
17	1997Q1	13162.00
18	1997Q2	17401.76
19	1997Q3	18528.58
20	1997Q4	17398.23
21	1998Q1	16098.85
22	1998Q2	18804.60
23	1998Q3	18785.81
24	1998Q4	16781.03
25	1999Q1	22153.37
26	1999Q2	24727.75
27	1999Q3	27646.22
28	1999Q4	29511.05
29	2000Q1	26401.85
30	2000Q2	30238.77
31	2000Q3	33767.67
32	2000Q4	31755.78
33	2001Q1	33576.48
34	2001Q2	40837.16
35	2001Q3	45700.99
36	2001Q4	42666.83
37	2002Q1	34811.53
38	2002Q2	38896.19
39	2002Q3	65893.98
40	2002Q4	72261.51
41	2003Q1	63030.91
42	2003Q2	62161.50
43	2003Q3	66753.63
44	2003Q4	68852.29
45	2004Q1	66312.69
46	2004Q2	82949.57
47	2004Q3	90341.26
48	2004Q4	84321.34
49	2005Q1	77093.40
50	2005Q2	82694.06
51	2005Q3	88086.50
52	2005Q4	83006.24
53	2006Q1	76051.28
54	2006Q2	79741.78
55	2006Q3	98607.88
56	2006Q4	91941.01
57	2007Q1	85073.57
58	2007Q2	89584.57
59	2007Q3	95806.74
60	2007Q4	92082.93
61	2008Q1	80459.15
62	2008Q2	98392.59
63	2008Q3	115435.04
64	2008Q4	126593.99
65	2009Q1	87414.68
66	2009Q2	93899.82
67	2009Q3	92906.41
68	2009Q4	87459.56
69	2010Q1	86801.18
70	2010Q2	105294.33
71	2010Q3	114224.84
72	2010Q4	115899.66
73	2011Q1	103744.07
74	2011Q2	124992.55
75	2011Q3	137086.16
76	2011Q4	141072.22
77	2012Q1	119042.78
78	2012Q2	146496.07
79	2012Q3	153302.60
80	2012Q4	153033.54
81	2013Q1	125319.87
82	2013Q2	156291.55
83	2013Q3	169810.17
84	2013Q4	174629.41
85	2014Q1	144496.77
86	2014Q2	162063.93
87	2014Q3	171654.97
88	2014Q4	158159.34
89	2015Q1	153323.91
90	2015Q2	189821.91
91	2015Q3	212635.31
92	2015Q4	217686.88
93	2016Q1	195483.57
94	2016Q2	208217.49
95	2016Q3	192878.21
96	2016Q4	184997.73
97	2017Q1	192447.13
98	2017Q2	216182.61
99	2017Q3	210281.20
100	2017Q4	205133.56
101	2018Q1	206113.14
102	2018Q2	239688.73
103	2018Q3	288391.86
104	2018Q4	276653.89
;
run;


data brazil;
  set brazil;
  Elog = log(Exports);
run;

ods listing close;
proc arima data=brazil;
identify var = exports; run;
* unequal variance, take the log;
 
identify var=elog stationarity =(adf=2) nlag=12; run;
* DF test suggest that difference is needed;
 
identify var = elog(1); run;
* seems to be seasonal every 2 records / 2 quarters by ACF, or every 4 records by trend plot;
 
**************** if season = 2 ********************;
identify var=elog(1,2) nlag=12; run;
 
* notice that (0) is not necessary, just to see the (p,d,q)x(P,D,Q);
estimate p = (0)(2) q = (0)(2) noconstant; run;
 
estimate p = (0)(2) q= (0)(4)  noconstant; run;
* significant model so far. aic= -142;
 
**************** if season = 4 ********************;
identify var=elog(1,4) nlag=24; run;
estimate p = (0)(0) q = (0)(4) noconstant; run;
* aic = -161 ==> better model than above;
 
**************** forcasting ********************;
forecast lead=12 out = out; run;
quit;
 
* Plot the forecasted value back to original units;
data plot;
  set out;
  y=exp(elog);
  l95=exp( l95 );
  u95=exp( u95 );
  forecast = exp(forecast+ std*std/2 );
  obs = _N_;
  if _N_ > 96;
run;
  
proc sgplot data=plot noautolegend;
 scatter x = obs y=forecast / yerrorlower=L95 yerrorupper=U95;
 series x = obs y=forecast;
 yaxis label='Forecasted Exports (millions real)';
 xaxis label='Years 2019-2021';
 run;
quit;

data plot;
  set plot;
  label Forecast ="Exports (in millions Real)"
        L95 = "Lower 95% confidence limit"
		U95 = "Upper 95% confidence limit"
  ;
proc report data=plot;
title1 "Table of Forecasted Values in 2019-2021 for Brazilian Exports";
column Forecast L95 U95;
define forecast / order;
run;

quit;
