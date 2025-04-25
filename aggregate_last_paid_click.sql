{\rtf1\ansi\ansicpg1251\cocoartf2820
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Bold;\f1\fnil\fcharset0 Menlo-Regular;\f2\fnil\fcharset0 Menlo-Italic;
}
{\colortbl;\red255\green255\blue255;\red115\green158\blue202;\red204\green204\blue204;\red158\green158\blue158;
\red0\green184\blue184;\red193\green170\blue108;\red183\green136\blue211;\red202\green197\blue128;\red192\green192\blue192;
\red102\green151\blue104;\red238\green204\blue100;}
{\*\expandedcolortbl;;\csgenericrgb\c45098\c61961\c79216;\csgenericrgb\c80000\c80000\c80000;\csgenericrgb\c61961\c61961\c61961;
\csgenericrgb\c0\c72157\c72157;\csgenericrgb\c75686\c66667\c42353;\csgenericrgb\c71765\c53333\c82745;\csgenericrgb\c79216\c77255\c50196;\csgenericrgb\c75294\c75294\c75294;
\csgenericrgb\c40000\c59216\c40784;\csgenericrgb\c93333\c80000\c39216;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\b\fs24 \cf2 WITH
\f1\b0 \cf3  \cf4 tagged_sessions\cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  (\cf0 \
\pard\pardeftab720\partightenfactor0
\cf3   
\f0\b \cf2 SELECT
\f1\b0 \cf3  \cf0 \
\cf3     \cf5 visitor_id\cf3 ,\cf0 \
\cf3     \cf5 visit_date\cf3 ::
\f0\b \cf6 date
\f1\b0 \cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  
\f2\i \cf5 visit_date
\f1\i0 \cf3 ,\cf0 \
\cf3     
\f0\b \cf6 LOWER
\f1\b0 \cf3 (\cf5 source\cf3 ) 
\f0\b \cf2 AS
\f1\b0 \cf3  
\f2\i \cf5 utm_source
\f1\i0 \cf3 ,\cf0 \
\cf3     
\f0\b \cf6 LOWER
\f1\b0 \cf3 (\cf5 medium\cf3 ) 
\f0\b \cf2 AS
\f1\b0 \cf3  
\f2\i \cf5 utm_medium
\f1\i0 \cf3 ,\cf0 \
\cf3     
\f0\b \cf6 LOWER
\f1\b0 \cf3 (\cf5 campaign\cf3 ) 
\f0\b \cf2 AS
\f1\b0 \cf3  
\f2\i \cf5 utm_campaign
\f1\i0 \cf3 ,\cf0 \
\cf3     
\f0\b \cf6 ROW_NUMBER
\f1\b0 \cf3 () 
\f0\b \cf2 OVER
\f1\b0 \cf3  (\cf0 \
\cf3       
\f0\b \cf2 PARTITION
\f1\b0 \cf3  
\f0\b \cf2 BY
\f1\b0 \cf3  \cf5 visitor_id\cf3  \cf0 \
\cf3       
\f0\b \cf2 ORDER
\f1\b0 \cf3  
\f0\b \cf2 BY
\f1\b0 \cf3  \cf5 visit_date\cf3  
\f0\b \cf2 DESC
\f1\b0 \cf0 \
\cf3     ) 
\f0\b \cf2 AS
\f1\b0 \cf3  
\f2\i \cf5 rn
\f1\i0 \cf0 \
\cf3   
\f0\b \cf2 FROM
\f1\b0 \cf3  \cf7 sessions\cf0 \
\cf3   
\f0\b \cf2 WHERE
\f1\b0 \cf3  
\f0\b \cf6 LOWER
\f1\b0 \cf3 (\cf5 medium\cf3 ) 
\f0\b \cf2 IN
\f1\b0 \cf3  (\cf8 'cpc'\cf3 , \cf8 'cpm'\cf3 , \cf8 'cpa'\cf3 , \cf8 'youtube'\cf3 , \cf8 'cpp'\cf3 , \cf8 'tg'\cf3 , \cf8 'social'\cf3 )\cf0 \
\cf3 ),\cf0 \
\
\pard\pardeftab720\partightenfactor0
\cf4 last_paid_clicks\cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  (\cf0 \
\pard\pardeftab720\partightenfactor0
\cf3   
\f0\b \cf2 SELECT
\f1\b0 \cf3  \cf0 \
\cf3     \cf4 visitor_id\cf3 ,\cf0 \
\cf3     \cf4 visit_date\cf3 ,\cf0 \
\cf3     \cf4 utm_source\cf3 ,\cf0 \
\cf3     \cf4 utm_medium\cf3 ,\cf0 \
\cf3     \cf4 utm_campaign\cf0 \
\cf3   
\f0\b \cf2 FROM
\f1\b0 \cf3  \cf4 tagged_sessions\cf0 \
\cf3   
\f0\b \cf2 WHERE
\f1\b0 \cf3  \cf4 rn\cf3  = \cf9 1\cf0 \
\cf3 ),\cf0 \
\
\pard\pardeftab720\partightenfactor0
\cf4 leads_data\cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  (\cf0 \
\pard\pardeftab720\partightenfactor0
\cf3   
\f0\b \cf2 SELECT
\f1\b0 \cf3  \cf0 \
\cf3     \cf4 visitor_id\cf3 ,\cf0 \
\cf3     \cf4 created_at\cf3 ::
\f0\b \cf6 date
\f1\b0 \cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  \cf4 lead_date\cf3 ,\cf0 \
\cf3     \cf4 amount\cf3 ,\cf0 \
\cf3     \cf4 closing_reason\cf3 ,\cf0 \
\cf3     \cf4 status_id\cf3 ,\cf0 \
\cf3     \cf4 lead_id\cf0 \
\cf3   
\f0\b \cf2 FROM
\f1\b0 \cf3  \cf4 leads\cf0 \
\cf3 ),\cf0 \
\
\pard\pardeftab720\partightenfactor0
\cf4 ads_combined\cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  (\cf0 \
\pard\pardeftab720\partightenfactor0
\cf3   
\f0\b \cf2 SELECT
\f1\b0 \cf0 \
\cf3     \cf4 campaign_date\cf3 ::
\f0\b \cf6 date
\f1\b0 \cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  \cf4 visit_date\cf3 ,\cf0 \
\cf3     
\f0\b \cf6 LOWER
\f1\b0 \cf3 (\cf4 utm_source\cf3 ) 
\f0\b \cf2 AS
\f1\b0 \cf3  \cf4 utm_source\cf3 ,\cf0 \
\cf3     
\f0\b \cf6 LOWER
\f1\b0 \cf3 (\cf4 utm_medium\cf3 ) 
\f0\b \cf2 AS
\f1\b0 \cf3  \cf4 utm_medium\cf3 ,\cf0 \
\cf3     
\f0\b \cf6 LOWER
\f1\b0 \cf3 (\cf4 utm_campaign\cf3 ) 
\f0\b \cf2 AS
\f1\b0 \cf3  \cf4 utm_campaign\cf3 ,\cf0 \
\cf3     
\f0\b \cf2 CASE
\f1\b0 \cf3  \cf0 \
\cf3       
\f0\b \cf2 WHEN
\f1\b0 \cf3  \cf4 daily_spent\cf3 ::
\f0\b \cf6 text
\f1\b0 \cf3  ~ \cf8 '^[0-9]+(\\.[0-9]+)?$'\cf3  
\f0\b \cf2 THEN
\f1\b0 \cf3  \cf4 daily_spent\cf3 ::
\f0\b \cf6 NUMERIC
\f1\b0 \cf0 \
\cf3       
\f0\b \cf2 ELSE
\f1\b0 \cf3  
\f0\b \cf2 NULL
\f1\b0 \cf0 \
\cf3     
\f0\b \cf2 END
\f1\b0 \cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  \cf4 daily_spent\cf0 \
\cf3   
\f0\b \cf2 FROM
\f1\b0 \cf3  \cf4 ya_ads\cf0 \
\cf3   
\f0\b \cf2 UNION
\f1\b0 \cf3  
\f0\b \cf2 ALL
\f1\b0 \cf0 \
\cf3   
\f0\b \cf2 SELECT
\f1\b0 \cf0 \
\cf3     \cf4 campaign_date\cf3 ::
\f0\b \cf6 date
\f1\b0 \cf3 ,\cf0 \
\cf3     
\f0\b \cf6 LOWER
\f1\b0 \cf3 (\cf4 utm_source\cf3 ),\cf0 \
\cf3     
\f0\b \cf6 LOWER
\f1\b0 \cf3 (\cf4 utm_medium\cf3 ),\cf0 \
\cf3     
\f0\b \cf6 LOWER
\f1\b0 \cf3 (\cf4 utm_campaign\cf3 ),\cf0 \
\cf3     
\f0\b \cf2 CASE
\f1\b0 \cf3  \cf0 \
\cf3       
\f0\b \cf2 WHEN
\f1\b0 \cf3  \cf4 daily_spent\cf3 ::
\f0\b \cf6 text
\f1\b0 \cf3  ~ \cf8 '^[0-9]+(\\.[0-9]+)?$'\cf3  
\f0\b \cf2 THEN
\f1\b0 \cf3  \cf4 daily_spent\cf3 ::
\f0\b \cf6 NUMERIC
\f1\b0 \cf0 \
\cf3       
\f0\b \cf2 ELSE
\f1\b0 \cf3  
\f0\b \cf2 NULL
\f1\b0 \cf0 \
\cf3     
\f0\b \cf2 END
\f1\b0 \cf0 \
\cf3   
\f0\b \cf2 FROM
\f1\b0 \cf3  \cf4 vk_ads\cf0 \
\cf3 ),\cf0 \
\
\pard\pardeftab720\partightenfactor0
\cf10 -- \uc0\u1054 \u1089 \u1085 \u1086 \u1074 \u1085 \u1072 \u1103  \u1090 \u1072 \u1073 \u1083 \u1080 \u1094 \u1072  \u1089  \u1074 \u1080 \u1079 \u1080 \u1090 \u1072 \u1084 \u1080  \u1080  \u1083 \u1080 \u1076 \u1072 \u1084 \u1080 \cf0 \
\pard\pardeftab720\partightenfactor0
\cf4 visits_with_leads\cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  (\cf0 \
\pard\pardeftab720\partightenfactor0
\cf3   
\f0\b \cf2 SELECT
\f1\b0 \cf0 \
\cf3     \cf4 v\cf3 .\cf4 visit_date\cf3 ,\cf0 \
\cf3     \cf4 v\cf3 .\cf4 utm_source\cf3 ,\cf0 \
\cf3     \cf4 v\cf3 .\cf4 utm_medium\cf3 ,\cf0 \
\cf3     \cf4 v\cf3 .\cf4 utm_campaign\cf3 ,\cf0 \
\cf3     \cf4 v\cf3 .\cf4 visitor_id\cf3 ,\cf0 \
\cf3     \cf4 l\cf3 .\cf4 lead_id\cf3 ,\cf0 \
\cf3     \cf4 l\cf3 .\cf4 amount\cf3 ,\cf0 \
\cf3     
\f0\b \cf2 CASE
\f1\b0 \cf3  \cf0 \
\cf3       
\f0\b \cf2 WHEN
\f1\b0 \cf3  \cf4 l\cf3 .\cf4 closing_reason\cf3  = \cf8 '\uc0\u1059 \u1089 \u1087 \u1077 \u1096 \u1085 \u1072 \u1103  \u1087 \u1088 \u1086 \u1076 \u1072 \u1078 \u1072 '\cf3  
\f0\b \cf2 OR
\f1\b0 \cf3  \cf4 l\cf3 .\cf4 status_id\cf3  = \cf9 142\cf3  
\f0\b \cf2 THEN
\f1\b0 \cf3  \cf9 1\cf0 \
\cf3       
\f0\b \cf2 ELSE
\f1\b0 \cf3  \cf9 0\cf0 \
\cf3     
\f0\b \cf2 END
\f1\b0 \cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  \cf4 is_purchase\cf0 \
\cf3   
\f0\b \cf2 FROM
\f1\b0 \cf3  \cf4 last_paid_clicks\cf3  \cf4 v\cf0 \
\cf3   
\f0\b \cf2 LEFT
\f1\b0 \cf3  
\f0\b \cf2 JOIN
\f1\b0 \cf3  \cf4 leads_data\cf3  \cf4 l\cf0 \
\cf3     
\f0\b \cf2 ON
\f1\b0 \cf3  \cf4 v\cf3 .\cf4 visitor_id\cf3  = \cf4 l\cf3 .\cf4 visitor_id\cf0 \
\cf3     
\f0\b \cf2 AND
\f1\b0 \cf3  \cf4 l\cf3 .\cf4 lead_date\cf3  >= \cf4 v\cf3 .\cf4 visit_date\cf0 \
\cf3 ),\cf0 \
\
\pard\pardeftab720\partightenfactor0
\cf10 -- \uc0\u1040 \u1075 \u1088 \u1077 \u1075 \u1080 \u1088 \u1086 \u1074 \u1072 \u1085 \u1085 \u1099 \u1077  \u1076 \u1072 \u1085 \u1085 \u1099 \u1077  \u1087 \u1086  \u1088 \u1077 \u1082 \u1083 \u1072 \u1084 \u1077 \cf0 \
\pard\pardeftab720\partightenfactor0
\cf4 ads_costs\cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  (\cf0 \
\pard\pardeftab720\partightenfactor0
\cf3   
\f0\b \cf2 SELECT
\f1\b0 \cf0 \
\cf3     \cf4 visit_date\cf3 ,\cf0 \
\cf3     \cf4 utm_source\cf3 ,\cf0 \
\cf3     \cf4 utm_medium\cf3 ,\cf0 \
\cf3     \cf4 utm_campaign\cf3 ,\cf0 \
\cf3     
\f0\b \cf6 SUM
\f1\b0 \cf3 (
\f0\b \cf6 COALESCE
\f1\b0 \cf3 (\cf4 daily_spent\cf3 , \cf9 0\cf3 )) 
\f0\b \cf2 AS
\f1\b0 \cf3  \cf4 total_cost\cf0 \
\cf3   
\f0\b \cf2 FROM
\f1\b0 \cf3  \cf4 ads_combined\cf0 \
\cf3   
\f0\b \cf2 GROUP
\f1\b0 \cf3  
\f0\b \cf2 BY
\f1\b0 \cf3  \cf9 1\cf3 , \cf9 2\cf3 , \cf9 3\cf3 , \cf9 4\cf0 \
\cf3 )\cf0 \
\
\pard\pardeftab720\partightenfactor0
\cf10 -- \uc0\u1060 \u1080 \u1085 \u1072 \u1083 \u1100 \u1085 \u1099 \u1081  \u1088 \u1077 \u1079 \u1091 \u1083 \u1100 \u1090 \u1072 \u1090 \cf0 \
\pard\pardeftab720\partightenfactor0

\f0\b \cf2 SELECT
\f1\b0 \cf0 \
\pard\pardeftab720\partightenfactor0
\cf3   
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 visit_date\cf3 ,\cf0 \
\cf3   
\f0\b \cf6 COUNT
\f1\b0 \cf3 (
\f0\b \cf2 DISTINCT
\f1\b0 \cf3  
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 visitor_id\cf3 ) 
\f0\b \cf2 AS
\f1\b0 \cf3  
\f2\i \cf5 visitors_count
\f1\i0 \cf3 ,\cf0 \
\cf3   
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 utm_source\cf3 ,\cf0 \
\cf3   
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 utm_medium\cf3 ,\cf0 \
\cf3   
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 utm_campaign\cf3 ,\cf0 \
\cf3   
\f0\b \cf6 COALESCE
\f1\b0 \cf3 (
\f2\i \cf7 ac
\f1\i0 \cf3 .\cf4 total_cost\cf3 , \cf9 0\cf3 )::
\f0\b \cf6 INT
\f1\b0 \cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  
\f2\i \cf5 total_cost
\f1\i0 \cf3 ,\cf0 \
\cf3   
\f0\b \cf6 COUNT
\f1\b0 \cf3 (
\f0\b \cf2 DISTINCT
\f1\b0 \cf3  
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 lead_id\cf3 ) 
\f0\b \cf2 FILTER
\f1\b0 \cf3  (
\f0\b \cf2 WHERE
\f1\b0 \cf3  
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 lead_id\cf3  
\f0\b \cf2 IS
\f1\b0 \cf3  
\f0\b \cf2 NOT
\f1\b0 \cf3  
\f0\b \cf2 NULL
\f1\b0 \cf3 ) 
\f0\b \cf2 AS
\f1\b0 \cf3  
\f2\i \cf5 leads_count
\f1\i0 \cf3 ,\cf0 \
\cf3   
\f0\b \cf6 COUNT
\f1\b0 \cf3 (
\f0\b \cf2 DISTINCT
\f1\b0 \cf3  
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 lead_id\cf3 ) 
\f0\b \cf2 FILTER
\f1\b0 \cf3  (
\f0\b \cf2 WHERE
\f1\b0 \cf3  
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 is_purchase\cf3  = \cf9 1\cf3 ) 
\f0\b \cf2 AS
\f1\b0 \cf3  
\f2\i \cf5 purchases_count
\f1\i0 \cf3 ,\cf0 \
\cf3   
\f0\b \cf6 COALESCE
\f1\b0 \cf3 (
\f0\b \cf6 SUM
\f1\b0 \cf3 (
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 amount\cf3 ) 
\f0\b \cf2 FILTER
\f1\b0 \cf3  (
\f0\b \cf2 WHERE
\f1\b0 \cf3  
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 is_purchase\cf3  = \cf9 1\cf3 ), \cf9 0\cf3 )::
\f0\b \cf6 INT
\f1\b0 \cf3  
\f0\b \cf2 AS
\f1\b0 \cf3  
\f2\i \cf5 revenue
\f1\i0 \cf0 \
\pard\pardeftab720\partightenfactor0

\f0\b \cf2 FROM
\f1\b0 \cf3  \cf4 visits_with_leads\cf3  \cf4 v\cf0 \

\f0\b \cf2 LEFT
\f1\b0 \cf3  
\f0\b \cf2 JOIN
\f1\b0 \cf3  \cf4 ads_costs\cf3  \cf4 ac\cf0 \
\pard\pardeftab720\partightenfactor0
\cf3   
\f0\b \cf2 ON
\f1\b0 \cf3  
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 visit_date\cf3  = 
\f2\i \cf7 ac
\f1\i0 \cf3 .\cf4 visit_date\cf0 \
\cf3   
\f0\b \cf2 AND
\f1\b0 \cf3  
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 utm_source\cf3  = 
\f2\i \cf7 ac
\f1\i0 \cf3 .\cf4 utm_source\cf0 \
\cf3   
\f0\b \cf2 AND
\f1\b0 \cf3  
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 utm_medium\cf3  = 
\f2\i \cf7 ac
\f1\i0 \cf3 .\cf4 utm_medium\cf0 \
\cf3   
\f0\b \cf2 AND
\f1\b0 \cf3  
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 utm_campaign\cf3  = 
\f2\i \cf7 ac
\f1\i0 \cf3 .\cf4 utm_campaign\cf0 \
\pard\pardeftab720\partightenfactor0

\f0\b \cf2 GROUP
\f1\b0 \cf3  
\f0\b \cf2 BY
\f1\b0 \cf0 \
\pard\pardeftab720\partightenfactor0
\cf3   
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 visit_date\cf3 ,\cf0 \
\cf3   
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 utm_source\cf3 ,\cf0 \
\cf3   
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 utm_medium\cf3 ,\cf0 \
\cf3   
\f2\i \cf7 v
\f1\i0 \cf3 .\cf4 utm_campaign\cf3 ,\cf0 \
\cf3   
\f2\i \cf7 ac
\f1\i0 \cf3 .\cf4 total_cost\cf0 \
\pard\pardeftab720\partightenfactor0

\f0\b \cf2 ORDER
\f1\b0 \cf3  
\f0\b \cf2 BY
\f1\b0 \cf0 \
\pard\pardeftab720\partightenfactor0
\cf3   
\f2\i \cf5 revenue
\f1\i0 \cf3  
\f0\b \cf2 DESC
\f1\b0 \cf3  
\f0\b \cf2 NULLS
\f1\b0 \cf3  
\f0\b \cf2 LAST
\f1\b0 \cf3 ,\cf0 \
\cf3   \cf4 v\cf3 .\cf4 visit_date\cf3  
\f0\b \cf2 ASC
\f1\b0 \cf3 ,\cf0 \
\cf3   \cf4 v\cf3 .\cf4 utm_source\cf3 ,\cf0 \
\cf3   \cf4 v\cf3 .\cf4 utm_medium\cf3 ,\cf0 \
\cf3   \cf4 v\cf3 .\cf4 utm_campaign\cf11 ;}