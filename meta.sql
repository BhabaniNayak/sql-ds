-- SQL Order of execution
/*
Order | Clause | Description
=============================
1 | FROM | Specifies the table(s) to query to retrieve rows
2 | WHERE | Filters the rows that satisfy the search condition
3 | GROUP BY | Groups the result set into subsets of rows
4   | HAVING | Filters out groups of rows that satisfy some condition
5 | SELECT | Selects the columns to be retrieved
5 | WINDOW FUNCTIONS | select over : Performs a calculation across a set of rows
    | OVER | Defines the window or group of rows that the function operates on.
    | PARTITION BY | Divides the query result set into partitions. The window function is applied to each partition separately and computation restarts for each partition.
    | ORDER BY | Sorts the rows in each partition to which the window function is applied. The order_by_clause is required. If you omit it, the order of the rows is nondeterministic.
6 | DISTINCT | Filters out duplicate rows from the result set.
7 | ORDER BY | Sorts the rows in the result set in ascending or descending order.
8 | LIMIT | Specifies that only the first set of rows will be returned from the query result.
*/

-- Common Functions

-- Date and Time
    -- datediff(date1, date2)	Returns the number of days between date1 and date2.
    -- timestampdiff(unit, timestamp1, timestamp2)	Returns the difference between timestamp1 and timestamp2, expressed as an integer in units of unit.
        -- unix_timestamp()	Returns the current Unix timestamp in seconds.
    -- year(date), month(date), day(date)	Returns the year, month, day of the date argument.
        -- extract(unit from date)	Returns the value of the given unit from the date argument.
    -- date_format(date, format)	Returns a date formatted according to the format string argument.
        -- date_format(reported_at, '%Y-%b'), '2022-Jan'
    -- time_format(time, format)	Returns a time formatted according to the format string argument.

-- Other
    -- replace(string, substring, replacement)	Replaces all occurrences of a substring within a string with a replacement string.
    -- substring_index(string, delimiter, count)	Returns the substring from string before count occurrences of the delimiter.
    -- char_length(string) Returns the length of the string measured in characters.
    -- length(string) Returns the length of the string measured in bytes.

--##########################################################################
--                              Easy
--##########################################################################




---------------------------------------------------------------------------
-- Who is the top poster?
    -- Find the top poster(s) on Facebook and count how many of each post type they had. 
    -- Please consider ties and return all users if tie exists. Order answer by creator asc and post type asc.

-- Source Tables
    -- fb_posts	
        -- post_id	bigint
        -- user_id	bigint
        -- creation_date	text
        -- post_type	text

-- Table Preview
    -- post_id	user_id	creation_date	post_type
    -- 1	6	2022-08-14 16:43:49	ad
    -- 2	14	2022-11-25 23:42:30	post
    -- 3	3	2022-03-17 15:14:36	video
    -- 4	8	2022-12-19 18:41:47	poll
    -- 5	12	2022-07-29 09:57:39	post

-- Concepts 
    -- Window Functions
    -- Common Table Expressions
    -- Aggregate Functions
    -- Filtering

-- Sample Output and Explanation
    -- creator | post_type |  total_posts
    -- return ties
    -- order by user_id asc, type asc

WITH top_users AS (
  SELECT
    user_id
    , rank() over(ORDER BY COUNT(*) DESC) as r -- rank by count of posts using window function
  FROM
    fb_posts
  GROUP BY 1
)

SELECT
  p.user_id as creator
  , p.post_type
  , COUNT(p.post_id) as total_posts
FROM
  fb_posts p
  JOIN top_users t ON (p.user_id = t.user_id AND t.r = 1)
group by 1,2
order by 1,2


---------------------------------------------------------------------------
-- Count the number of unique users per day who logged in from both a mobile device and web. Output the date and the corresponding number of users.
SELECT 
    m.date,
    COUNT(DISTINCT m.user_id) AS n_users
FROM 
    mobile_logs m 
    JOIN web_logs w ON m.user_id = w.user_id AND m.date = w.date
GROUP BY m.date;

---------------------------------------------------------------------------
-- What percentage of all products are both low fat and recyclable?
select 
    count(case when is_low_fat = 'Y' and is_recyclable = 'Y' then product_id else null end)/count(*)*100 as percentage
from 
    facebook_products;

---------------------------------------------------------------------------
-- Find the percentage of sales with promotion IDs from the online_promotions table applied.
select 
    count(case when p.promotion_id is not null then p.promotion_id else null end)/count(*)*100 as percentage
from 
    online_orders o
    left join online_promotions p on o.promotion_id=p.promotion_id;

---------------------------------------------------------------------------
-- Count the number of users who made more than 5 searches in August 2021.
with base_data as (
select 
    user_id
    ,count(search_id) as searches
from fb_searches
where
    date between '2021-08-01' and '2021-08-31' -- date filter
group by 1
    having searches>5 -- search condition filter
)
select count(user_id) as result from base_data
;

-- How many searches were there in the second quarter of 2021?
SELECT count(search_id) AS RESULT
FROM fb_searches
WHERE QUARTER(date) = 2
  AND YEAR(date) = 2021

---------------------------------------------------------------------------
-- Return the total number of comments received for each user in the 30 or less days before 2020-02-10. 
-- Don't output users who haven't received any comment in the defined time period.
select 
    user_id
    ,sum(number_of_comments) as number_of_comments
from 
    fb_comments_count
where
    created_at >= '2020-02-10' - INTERVAL 30 DAY -- date filter lower bound with relative days
    AND created_at <= '2020-02-10' -- date filter upper bound
group by 1
;

---------------------------------------------------------------------------
-- Return a distribution of users activity per day of the month. By distribution we mean the number of posts per day of the month.
select
    day(post_date) -- how to get day of month
    , count(post_id)
from
    facebook_posts
group by 1

---------------------------------------------------------------------------
-- Find all messages which have references to either user 2 or 3.
select * from facebook_messages_sent
where lower(text) like '%user 2%' or lower(text) like '%user 3%' -- use of like and lower to match case insensitive

---------------------------------------------------------------------------
-- Find whether the number of senior workers (i.e., more experienced) at Meta/Facebook is higher than number of USA based employees at Facebook/Meta.
-- If the number of seniors is higher then output as 'More seniors'. Otherwise, output as 'More USA-based'.

-- facebook_employees
-- id	location	age	gender	is_senior
-- 0	USA	24	M	0
-- 1	USA	31	F	1
-- 2	USA	29	F	0
-- 3	USA	33	M	0
-- 4	USA	36	F	1

-- winner
with base as (
select
    sum(case when location = 'USA' then 1 else 0 end) as n_us_employees
    , sum(case when location <> 'USA' then 1 else 0 end) as n_non_us_employees
from
    facebook_employees
)
select
    case when n_us_employees < n_non_us_employees then 'More seniors' else 'More USA-based' end as winner
from base

---------------------------------------------------------------------------
-- Meta/Facebook Matching Users Pairs
-- Find matching pairs of Meta/Facebook employees such that they are both of the same nation, different age, same gender, and at different seniority levels.
-- Output ids of paired employees.

-- facebook_employees
-- id	location	age	gender	is_senior
-- 0	USA	24	M	0
-- 1	USA	31	F	1
-- 2	USA	29	F	0
-- 3	USA	33	M	0
-- 4	USA	36	F	1

-- employee_1 | employee_2
-- same location, different age, same gender, different is_senior
select
    a.id as employee_1
    ,b.id as employee_2
from
    facebook_employees a
    join facebook_employees b on -- note self join with multiple conditions
        a.location = b.location
        and a.age <> b.age
        and a.gender = b.gender
        and a.is_senior <> b.is_senior

---------------------------------------------------------------------------
-- Liked' Posts
-- facebook_reactions
-- poster	friend	reaction	date_day	post_id
-- 2	1	like	1	0
-- 2	6	like	1	0
-- 1	2	like	1	1
-- 1	3	heart	1	1
-- 1	4	like	1	1

-- facebook_posts
-- post_id	poster	post_text	post_keywords	post_date
-- 0	2	The Lakers game from last night was great.	[basketball,lakers,nba]	2019-01-01
-- 1	1	Lebron James is top class.	[basketball,lebron_james,nba]	2019-01-02
-- 2	2	Asparagus tastes OK.	[asparagus,food]	2019-01-01
-- 3	1	Spaghetti is an Italian food.	[spaghetti,food]	2019-01-02
-- 4	3	User 3 is not sharing interests	[#spam#]	2019-01-01

-- n_posts_with_a_like
--  reaction = like
select
    count(distinct r.post_id) as n_posts_with_a_like
from
    facebook_reactions r
    -- join facebook_posts p on r.post_id = p.post_id -- with join and without join works
where
    r.reaction = 'like'

---------------------------------------------------------------------------
-- Spam Posts Percentage by Date
select
    post_date
    , count(case when post_keywords like '%spam%' then p.post_id end) / count(*)*100 as spam_share
from
    facebook_posts p
    join facebook_post_views v on p.post_id = v.post_id
group by 1

---------------------------------------------------------------------------
-- Find the number of processed and not-processed complaints of each type

-- facebook_complaints
-- complaint_id	type	processed
-- 0	0	1
-- 1	0	1
-- 2	0	0
-- 3	1	1
select
    type
    , sum(processed) as n_complaints_processed
    , sum(case when processed=0 or processed is null then 1 end) as n_complaints_not_processed
from
    facebook_complaints
group by type

---------------------------------------------------------------------------
-- Acceptance Rate
select
    round(count(a.acceptor_id) / count(r.requester_id), 4) as acceptance_rate
from 
    friend_requests r
    left join friend_accepts a on r.requester_id = a.requester_id
---------------------------------------------------------------------------
-- Daily active users
select
    platform
    ,created_at
    ,count(distinct user_id) as daily_users
from events
where year(created_at) = 2020
group by 1,2
---------------------------------------------------------------------------

---------------------------------------------------------------------------


--##########################################################################
--                          Medium
--##########################################################################

-- Reported Posts
    -- Find the number of posts reported each month by each reason in 2022
    -- Find the percentage of posts that are reviewed after being reported
    -- Find the percentage that each risk type makes up or reported population
    -- Find the percentage of posts that are reported by each reason
    -- Find the #1 reason why posts are reported and return its percentage of posts
    -- Find the percentage of posts that are removed after being reported?

-- What is the trend in each report reason?
-- Find the number of posts reported each month by each reason in 2022, you can leave duplicates in 
-- since we are interested in volumes. Return answer sorted by reason asc and month asc. 
-- Be careful the months are in order! 

-- Data
-- reported_by	post_id	posted_by	reported_reason	risk_rating	reported_at	is_reviewed	is_removed
-- 31	46	6	spam	Low	2022-08-14	0	0
-- 11	45	3	crime	Low	2022-11-25	0	0
-- 45	18	16	explicit_content	Low	2022-03-17	0	0
-- 7	43	17	explicit_content	Medium	2022-12-19	1	0
-- 33	20	16	spam	Low	2022-07-29	0	0

-- Expected Output:
-- mon_yr	reported_reason	posts_reported
-- 2022-Mar	bullying	3
-- 2022-Jun	bullying	2
-- 2022-Aug	bullying	1
-- 2022-Sep	bullying	1
-- 2022-May	crime	1

-- Concepts
    -- Date Functions
with base as
(
    SELECT
        date_format(reported_at, '%Y-%b') as mon_yr
        , month(reported_at) as month_num
        , reported_reason
        , COUNT(post_id) as posts_reported
    FROM 
        fb_reported_posts
    WHERE
        year(reported_at) = '2022'
    GROUP BY 1,2,3 
)

select 
    mon_yr, 
    reported_reason, 
    posts_reported 
from base 
order by reported_reason, month_num

-- Find the percentage of posts that are reviewed after being reported to the company. Round you answer to 2 decimals.
SELECT
  ROUND(100*SUM(is_reviewed) / COUNT(*),2) as review_rate
FROM
  fb_reported_posts


-- Find the percentage that each risk type makes up or reported population. 
-- Round answer to 2 decimals and sort by risk percent desc. Remember to only count a given post 1 time per risk rating.
-- risk percentage = risk_type unique posts / total unique posts
SELECT
  risk_rating
  , ROUND( 100*COUNT(DISTINCT post_id) / (SELECT COUNT(DISTINCT post_id) FROM fb_reported_posts),2) as risk_percentage
FROM
  fb_reported_posts
GROUP BY 1
ORDER BY 2 DESC


-- Find the #1 reason why posts are reported and return its percentage of posts rounded to 2 decimals. 
-- Sort by percent desc and reason asc. Return ONLY 1 Row.
SELECT
  reported_reason
  , round (100*COUNT(*) / (SELECT COUNT(*) FROM fb_reported_posts), 2) as report_rate
FROM fb_reported_posts
GROUP BY 1
ORDER BY 2 DESC, 1 ASC
LIMIT 1


-- Find the percentage of posts that are removed after being reported? Round you answer to 2 decimals.
SELECT
  round(100 * count(distinct case when is_removed=1 THEN post_id end) / COUNT(DISTINCT post_id),2) as removal_rate
FROM
  fb_reported_posts

-- Find the percentage of posts that are reported by each reason. Round you answer to 2 decimals and sort by percent desc reason asc.
SELECT
  reported_reason
  , round (100* COUNT(*) / (select count(*) from fb_reported_posts), 2) as report_rate
FROM
  fb_reported_posts
GROUP BY 1
ORDER BY 2 DESC, 1 ASC

---------------------------------------------------------------------------

-- Find the CTR rate for each ad and round answer to 2 decimals. Sort answer by ctr desc and ad asc.

-- ad_exp_id	ad_name	cpc_rate	clicked_ad
-- 1	Spotify Prem	0.1	0
-- 2	Cosmetics Holiday Sale	0.32	1
-- 3	Spotify Prem	0.1	0
-- 4	Disney+ Bundle	0.07	1
-- 5	Charty Inc Trial	0.43	0

SELECT
  ad_name
  , round(100*sum(clicked_ad) / count(*),2) as ad_ctr
FROM
  ads_actions
GROUP BY 1
ORDER BY 2 DESC, 1 ASC


-- Find the total Ad Spend spend for each ad. Ad spend is a sumation of CPC, or Cost Per Click. 
-- This is what advertisers agree to pay for in campaign setup. Sort answer by ad spend desc and ad asc. 
-- Round all answers to 2 decimals.
SELECT
  ad_name
  ,round(sum(case when clicked_ad = 1 then cpc_rate else 0 end),2) as ad_spend
FROM
  ads_actions
GROUP BY 1
order BY 2 DESC, 1 ASC


---------------------------------------------------------------------------

-- Find the percentage of posts that receive a like or comment raction type. Round your answer to 2 decimials.

-- post_id	user_id	action_datetime	reaction_type
-- 16	66	2022-08-14 16:43:49	comment
-- 18	10	2022-11-25 23:42:30	share
-- 20	41	2022-03-17 15:14:36	comment
-- 15	26	2022-12-19 18:41:47	share
-- 39	60	2022-07-29 09:57:39	like

select 
round( (count(distinct case when reaction_type in ('like', 'comment') then post_id else null end) 
/ count(distinct post_id) * 100 ), 2) like_commnt_rate 
from fb_posts_actions



---------------------------------------------------------------------------

-- Find the number of polls that were created on Facebook for each month year combination Return your answers sorted by year, month ascending.

-- post_id	user_id	creation_date	post_type
-- 1	6	2022-08-14 16:43:49	ad
-- 2	14	2022-11-25 23:42:30	post
-- 3	3	2022-03-17 15:14:36	video
-- 4	8	2022-12-19 18:41:47	poll
-- 5	12	2022-07-29 09:57:39	post

SELECT
  year(creation_date) as poll_year
  , month(creation_date) as poll_month
  , count(*) as polls
FROM
  fb_posts
WHERE
  post_type = 'poll'
GROUP BY 1,2
ORDER BY 1,2


---------------------------------------------------------------------------

-- AB Experiment Evaluation

-- The day is here and data is finally in from your AB experiment. 
-- The data is in from your experiment. But, before you calculate the control metric, 
-- test metric and delta change you need to check the sample sizes are about equal. 
-- Calculate the total users in the control group and treatment group for each test. Order by test name asc

-- exp_res_id	test_name	treatment_group	metric_value	is_internal_acc	double_exposure
-- 1	ML Ranking Algo Feed	Control	0.72	0	0
-- 2	Green Button v2	Test	7.82	0	0
-- 3	Icons Rearranged	Test	2.42	0	0
-- 4	Icons Rearranged	Control	5.16	0	0
-- 5	ML Ranking Algo Feed	Control	2.08	0	0

SELECT
  test_name
  , sum(case when treatment_group = 'Test' then 1 else 0 end) as treatment_count
  , sum(case when treatment_group = 'Control' then 1 else 0 end) as control_count
FROM
  ab_exp_results
GROUP BY 1
order BY 1


-- Calculate the avg control metric, test metric, and delta change for each experiment. 
-- Be careful of internal test accounts or wrongly assigned groups muddying the results. 
-- Round intermediary and final calcs to 2 decimals and order by test name asc.


with base as (
SELECT
  test_name
  , ROUND(AVG(case when treatment_group = 'Control' then metric_value end),2) as control_metric
  , ROUND(AVG(case when treatment_group = 'Test' then metric_value end),2) as test_metric
FROM
  ab_exp_results
WHERE
  is_internal_acc = 0
  AND double_exposure = 0
GROUP BY 1
)

SELECT
  test_name
  , control_metric
  , test_metric
  , round((test_metric - control_metric),2) as delta_chg
FROM
  base
ORDER BY 1

---------------------------------------------------------------------------

-- Calculate the number of days since a users first session. Assume today is 2022-05-26. Return answers sorted by days desc and user_id asc.

-- user_id	session_ts	session_type
-- 3	2021-03-27 09:27:39	sess_start
-- 8	2021-10-19 23:25:01	sess_end
-- 4	2020-05-31 06:29:12	sess_start
-- 5	2021-12-06 13:23:34	
-- 7	2021-02-22 19:55:18	sess_start

with base as (
  SELECT
    user_id
    , date(min(session_ts)) as first_session  
  FROM
    ig_user_sessions
  GROUP by 1
)
select
  user_id
  , first_session
  , datediff(date('2022-05-26'),first_session) as days_since_first_session
FROM
  base
order by 3 DESC, 1 ASC

---------------------------------------------------------------------------

-- You're on the content team at Meta and are asked to prepare a prettyifed report 
-- for leadership breaking down the counts of each post type for the month of January 2022.

-- post_id	user_id	creation_date	post_type
-- 1	6	2022-08-14 16:43:49	ad
-- 2	14	2022-11-25 23:42:30	post
-- 3	3	2022-03-17 15:14:36	video
-- 4	8	2022-12-19 18:41:47	poll
-- 5	12	2022-07-29 09:57:39	post

SELECT
  date_format(creation_date, '%Y-%b') as mon_yr
  , sum(case when post_type = 'post' then 1 else 0 end) as posts
  , sum(case when post_type = 'ad' then 1 else 0 end) as ads
  , sum(case when post_type = 'video' then 1 else 0 end) as video
  , sum(case when post_type = 'photo' then 1 else 0 end) as photos
  , sum(case when post_type = 'poll' then 1 else 0 end) as polls
FROM
  fb_posts
WHERE
  date_format(creation_date, '%Y-%b') = '2022-Jan'
GROUP BY 1


---------------------------------------------------------------------------

-- In order to improve customer segmentation efforts for users interested in purchasing furniture, 
-- you have been asked to find customers who have purchased the same items of furniture.

-- Output the product_id, brand_name, unique customer ID's who purchased that product, 
-- and the count of unique customer ID's who purchased that product. Arrange the output in descending order with the highest count at the top.

-- online_orders
-- product_id	promotion_id	cost_in_dollars	customer_id	date	units_sold
-- 1	1	2	1	2022-04-01	4
-- 3	3	6	3	2022-05-24	6
-- 1	2	2	10	2022-05-01	3
-- 1	2	3	2	2022-05-01	9
-- 2	2	10	2	2022-05-01	1

-- online_products
-- product_id	product_class	brand_name	is_low_fat	is_recyclable	product_category	product_family
-- 1	ACCESSORIES	Fort West	N	N	3	GADGET
-- 2	DRINK	Fort West	N	Y	2	CONSUMABLE
-- 3	FOOD	Fort West	Y	N	1	CONSUMABLE
-- 4	DRINK	Golden	Y	Y	3	CONSUMABLE
-- 5	FOOD	Golden	Y	N	2	CONSUMABLE

-- product_id | brand_name | customer_id | unique_cust_no

with product_unique_customers as (
    select
        p.product_id
        ,p.brand_name
        ,COUNT(distinct customer_id) as unique_cust_no
    from
        online_orders o
        join online_products p on o.product_id = p.product_id
    where 
        product_class = 'FURNITURE' -- important filter can be easily ignored. look for column and value to get the right filter
    group by 1,2
)
, product_customer as (
    select distinct
        product_id
        , customer_id
    from
        online_orders
)

select u.product_id, u.brand_name, c.customer_id, u.unique_cust_no
from product_unique_customers u 
join product_customer c on u.product_id = c.product_id
order by 4 desc

---------------------------------------------------------------------------

-- Following a recent advertising campaign, you have been asked to compare the sales of consumable products across all brands.
-- Compare the brands by finding the percentage of unique customers (among all customers in the dataset) who purchased consumable products from each brand.
-- Your output should contain the brand_name and percentage_of_customers rounded to the nearest whole number and ordered in descending order.

-- online_orders    
-- product_id	promotion_id	cost_in_dollars	customer_id	date	units_sold
-- 1	1	2	1	2022-04-01	4
-- 3	3	6	3	2022-05-24	6
-- 1	2	2	10	2022-05-01	3
-- 1	2	3	2	2022-05-01	9

-- online_products
-- product_id	product_class	brand_name	is_low_fat	is_recyclable	product_category	product_family
-- 1	ACCESSORIES	Fort West	N	N	3	GADGET
-- 2	DRINK	Fort West	N	Y	2	CONSUMABLE
-- 3	FOOD	Fort West	Y	N	1	CONSUMABLE
-- 4	DRINK	Golden	Y	Y	3	CONSUMABLE
-- 5	FOOD	Golden	Y	N	2

select
    brand_name
    , round(count(distinct customer_id) / (select count(distinct customer_id) from online_orders) *100,0) as pc_cust
from 
    online_orders o
    JOIN online_products p on p.product_id = o.product_id
where
    product_family = 'CONSUMABLE'
group by brand_name
;

---------------------------------------------------------------------------
-- The sales department wants to find lower priced products that sell well.
-- Find product IDs that were sold at least twice and have an average sales price of at least $3.
-- Your output should contain the product ID and its corresponding brand.
--  product_id | brand_name
-- sold at least twice, avg sales price at least $3

with product_sales as (
select
    product_id
    ,count(promotion_id) as sold_count
    ,avg(cost_in_dollars) as avg_sales_price
from 
    online_orders
group by 1
)
select
    s.product_id
    , p.brand_name
from
    product_sales s
    join online_products p on s.product_id = p.product_id
where
    sold_count >= 2
    and avg_sales_price >= 3

---------------------------------------------------------------------------
-- Find the top 3 product classes according to their number of sales for the most successful product classes
with base as (
select
    p.product_class -- note that the join is required to get the product class first for ranking as the question is asking for product class. rank by product id will have different result
    ,rank() over(order by count(*) desc) as r
from
    online_orders b
    join online_products p on b.product_id = p.product_id
group by 1)
select product_class from base
where r <= 3

---------------------------------------------------------------------------
-- customers who have purchased products from two particular brands: Fort West and Golden
WITH cte AS (
    SELECT customer_id, o.product_id, brand_name
    FROM online_orders o
    JOIN online_products p ON o.product_id = p.product_id
    )
    ,fort_west AS (
        SELECT DISTINCT customer_id
        FROM cte
        WHERE brand_name = 'Fort West'
    )
    ,golden AS (
        SELECT DISTINCT customer_id
        FROM cte
        WHERE brand_name = 'Golden'
    )
    SELECT f.customer_id
    FROM fort_west f
    INNER JOIN golden g ON f.customer_id = g.customer_id;
---------------------------------------------------------------------------

-- The VP of Sales feels that some product categories don't sell and can be completely removed from the inventory.
-- As a first pass analysis, they want you to find what percentage of product categories have never been sold.

select
    100*(1 - (count(distinct product_category) / count(distinct category_id))) as percentage_of_unsold_categories
from 
    online_product_categories c
    left join online_products p on p.product_category = c.category_id
    left join online_orders o on o.product_id = p.product_id

---------------------------------------------------------------------------
-- They are especially interested in comparing the sales on the first day vs. the last day of each promotion.
-- Segment the results by promotion and find the percentage of transactions that happened on the first and last day of each.

-- promotion_id	start_date	end_date	media_type	cost
-- 1	2022-04-01	2022-04-07	Internet	25000
-- 2	2022-05-01	2022-05-02	Broadcast	14000
-- 3	2022-05-24	2022-06-01	Print	32000
-- 4	2022-06-05	2022-06-10	Broadcast	18000
-- 5	2022-07-06	2022-07-12	Outdoor	20000

-- product_id	promotion_id	cost_in_dollars	customer_id	date	units_sold
-- 1	1	2	1	2022-04-01	4
-- 3	3	6	3	2022-05-24	6
-- 1	2	2	10	2022-05-01	3
-- 1	2	3	2	2022-05-01	9
-- 2	2	10	2	2022-05-01	1

with base as (
select
    p.promotion_id
    , sum(case when p.start_date = o.date then 1 else 0 end) as start_date_sales
    , sum(case when p.end_date = o.date then 1 else 0 end) as end_date_sales
    , count(*) as total_sales
from 
    online_sales_promotions p
    join online_orders o on o.promotion_id = p.promotion_id
group by 1
)
select 
    promotion_id
    , 100*start_date_sales/total_sales as start_date_percentage
    , 100*end_date_sales / total_sales as end_date_percentage
from base

---------------------------------------------------------------------------
-- You have been asked to find which products sold the most units for each promotion.

-- online_orders
-- product_id	promotion_id	cost_in_dollars	customer_id	date	units_sold
-- 1	1	2	1	2022-04-01	4
-- 3	3	6	3	2022-05-24	6
-- 1	2	2	10	2022-05-01	3

with base as
(select
    promotion_id
    , product_id
    , sum(units_sold) as units_sold
from online_orders
group by 1,2
)
, base_rank as (
select
    promotion_id
    , product_id
    , units_sold
    , DENSE_RANK() over(partition by promotion_id order by units_sold desc) as rank_order
from base
)
select
    promotion_id
    , product_id
    , units_sold
from base_rank
where rank_order = 1
;


---------------------------------------------------------------------------
-- finding the top two single-channel media types (ranked in decreasing order) that correspond to the most money the grocery chain had spent on its promotional campaigns.
-- Your output should contain the media type and the total amount spent on the advertising campaign. In the event of a tie, output all results and do not skip ranks.

-- money spent on campaign by grocery chain on media type
-- top 2 single-channel media types
-- descending
-- for tie, output all
-- media_type | money_spent

-- spend by media type
with base_spend as (
    select
        media_type
        , sum(cost) as money_spent
        , dense_rank() over(order by sum(cost) desc) as r -- no need for partition by as we are ranking across the entire dataset by media_type which is already grouped by
    from
        online_sales_promotions
    group by 1
)
select
    media_type, money_spent
from base_spend 
where r <=2 
order by 2 desc
-- revisit

---------------------------------------------------------------------------
-- You are given a table of users who have been blocked from Facebook, together with the date, duration, and the reason for the blocking. 
-- The duration is expressed as the number of days after blocking date and if this field is empty, this means that a user is blocked permanently.
-- For each blocking reason, count how many users were blocked in December 2021. Include both the users who were blocked in December 2021 
-- and those who were blocked before but remained blocked for at least a part of December 2021.

-- fb_blocked_users
-- user_id	block_reason	block_date	block_duration
-- 3642	Fake Account	2021-12-03	15
-- 2847	Fake Account	2021-12-15	120
-- 1239	Fake Account	2021-11-19	11

--  block_reason | n_users
-- block_date betweeen '20221-12-01' and '2021-12-31'
--  or block_date + block_duration betweeen '20221-12-01' and '2021-12-31'
--  or block_duration is null
select
    block_reason
    ,count(distinct user_id) as n_users -- distinct as users can be blocked multiple times in a month for same reason (data)
from
    fb_blocked_users
where
    extract(year from block_date) = 2021 and extract(month from block_date) = 12
    or block_duration is null -- permanent user is still blocked for the month
    or DATE_ADD(block_date, INTERVAL block_duration DAY) between '2021-12-01' and '2021-12-31'
group by 1
-- revisit

---------------------------------------------------------------------------
-- Count the total number of distinct conversations on WhatsApp. 
-- Two users share a conversation if there is at least 1 message between them. Multiple messages between the same pair of users are considered a single conversation.

-- whatsapp_messages
-- message_id	message_date	message_time	message_sender_id	message_receiver_id
-- 8187	2021-10-09	8:34	U1	U2
-- 5911	2021-10-17	11:49	U1	U2
-- 930	2021-11-09	2:20	U1	U3
-- 5721	2021-11-12	2:47	U1	U6
-- 5404	2021-12-04	9:12	U1	U3

-- number_of_conversations
-- conversation - sender and receiver pair
--      multiple messages between same pair - single conversation
-- distinct 
with base as (
    select message_sender_id,message_receiver_id from whatsapp_messages
    UNION -- no duplicates 
    select message_receiver_id as message_sender_id, message_sender_id as message_receiver_id from whatsapp_messages (trick)
)
select count(*) from base
where message_sender_id < message_receiver_id -- filter one of the row for U1->U2, U2->U1 (trick)
-- revisit

---------------------------------------------------------------------------
-- Recomender System

-- You are given the list of Facebook friends and the list of Facebook pages that users follow. 
-- Your task is to create a new recommendation system for Facebook. For each Facebook user, 
-- find pages that this user doesn't follow but at least one of their friends does. 
-- Output the user ID and the ID of the page that should be recommended to this user.

-- user_id	friend_id
-- 1	2
-- 1	4
-- 1	5

-- user_id	page_id
-- 1	21
-- 1	25
-- 2	25

-- user_id | page_id (do not follow but friends follow)
--  get user_id | friend_id -> page_id
-- filter user already followed

with base_recom as (
    select
        u.user_id
        ,p.page_id
    from
        users_friends u
        join users_pages p on u.friend_id = p.user_id -- join on pages on friend id to get the recommended pages
)
select distinct
    b.user_id,b.page_id
from
    base_recom b
    left join users_pages p on b.user_id = p.user_id and b.page_id = p.page_id -- left join on pages on base recom on user id and page id
where
    p.user_id is null -- filter out pages already followed by user
-- revisit

---------------------------------------------------------------------------
-- Most Active Users on Facebook Messenger

-- Meta/Facebook Messenger stores the number of messages between users in a table named 'fb_messages'. 
-- In this table 'user1' is the sender, 'user2' is the receiver, and 'msg_count' is the number of messages exchanged between them.
-- Find the top 10 most active users on Meta/Facebook Messenger by counting their total number of messages sent and received. 
-- Your solution should output usernames and the count of the total messages they sent or received

-- fb_messages
-- id	date	user1	user2	msg_count
-- 1	2020-08-02	kpena	scottmartin	2
-- 2	2020-08-02	misty19	srogers	2
-- 3	2020-08-02	jerome75	craig23	3
-- 4	2020-08-02	taylorhoward	johnmccann	8
-- 5	2020-08-02	wangdenise	sgoodman	2

-- username | total_msg_count
-- top 10
-- total number of messages sent and received
with base as (
    select user1, user2, msg_count from fb_messages
    UNION ALL -- note the use of UNION ALL as users exchange messages in multiple days and we want total count
    select user2 as user1, user1 as user2, msg_count from fb_messages
)
, msg_agg as (
    select
        user1 as username
        ,sum(msg_count) as total_msg_count
        ,rank() over(order by sum(msg_count) desc) as r
    from 
        base
    group by 1
)
select username, total_msg_count
from msg_agg
where r <= 10
-- revisit (UNION ALL vs UNION based on the data and use case)

---------------------------------------------------------------------------
-- SMS Confirmations From Users

-- Meta/Facebook sends SMS texts when users attempt to 2FA (2-factor authenticate) into the platform to log in. In order to successfully 2FA 
-- they must confirm they received the SMS text message. Confirmation texts are only valid on the date they were sent.
-- Unfortunately, there was an ETL problem with the database where friend requests and invalid confirmation records were inserted into the logs, 
-- which are stored in the 'fb_sms_sends' table. These message types should not be in the table.
-- Fortunately, the 'fb_confirmers' table contains valid confirmation records so you can use this table to identify SMS text messages that were confirmed by the user.
-- Calculate the percentage of confirmed SMS texts for August 4, 2020. Be aware that there are multiple message types, the ones you're interested in are messages with type equal to 'message'.

-- fb_sms_sends
-- ds	country	carrier	phone_number	type
-- 2020-08-07	ES	at&t	9812768911	confirmation
-- 2020-08-02	AD	sprint	9812768912	confirmation
-- 2020-08-04	SA	at&t	9812768913	message
-- 2020-08-02	AU	sprint	9812768914	message
-- 2020-08-07	GW	rogers	9812768915	message

-- fb_confirmers
-- date	phone_number
-- 2020-08-06	9812768960
-- 2020-08-03	9812768961
-- 2020-08-05	9812768962
-- 2020-08-02	9812768963
-- 2020-08-06	9812768964

-- perc - percentage of confirmed SMS texts
-- fb_sms_sends left join fb_confirmers on date, phone_number
-- type = 'message'
-- August 4, 2020
select
    round(count(case when c.date is not null and c.phone_number is not null then s.phone_number else null end) / count(*) * 100)
from 
    fb_sms_sends s
    left join fb_confirmers c on s.ds = c.date and s.phone_number = c.phone_number
where
    s.ds = '2020-08-04'
    and s.type = 'message'
-- revisit

---------------------------------------------------------------------------
-- Daily Interactions By Users Count

-- Find the number of interactions along with the number of people involved with them on a given day. 
-- Be aware that user1 and user2 columns represent user ids. Output the date along with the number of interactions and people. 
-- Order results based on the date in ascending order and the number of people in descending order.

-- facebook_user_interactions
-- day	user1	user2
-- 0	0	1
-- 0	1	0
-- 0	2	1
-- 0	2	3

-- day|	n_interactions | n_people
-- interactions = count(*)
-- number of people = distinct user1 after union
--  date asc, n_people desc
with interactions as (
    select 
        day
        , count(*) as n_interactions
    from
        facebook_user_interactions
    group by 1
)
, all_users as (
    select day, count(distinct user1) as n_people from
    (
        select day, user1, user2
        from facebook_user_interactions
        UNION
        select day, user2 as user1, user1 as user2
        from facebook_user_interactions
    )iq group by 1
)
select i.day,i.n_interactions,a.n_people
from
    interactions i
    join all_users a on i.day = a.day
order by day, n_people desc
-- revisit

---------------------------------------------------------------------------
-- Successfully Sent Messages

-- facebook_messages_sent
-- sender	message_id	text
-- 0	0	Hello from User 0 to User 1
-- 0	1	Hello from User 0 to User 3
-- 0	2	Hello from User 0 to User 5
-- 2	3	Hello from User 2 to User 4

-- facebook_messages_received
-- receiver	message_id	text
-- 1	0	Hello from User 0 to User 1
-- 5	2	Hello from User 0 to User 5
-- 0	4	Hello from User 2 to User 0

with sent as (
    select count(*) as n_sent
    from facebook_messages_sent
)
, received as (
    select
        count(*) as n_received
    from
        facebook_messages_sent s
        join facebook_messages_received r on s.message_id = r.message_id
)
select n_received / n_sent from sent, received;

---------------------------------------------------------------------------
-- Day 1 Common Reactions
-- Find the most common reaction for day 1 by counting the number of occurrences for each reaction. Output the reaction alongside its number of occurrences.

-- Table: facebook_reactions
-- poster	friend	reaction	date_day	post_id
-- 2	1	like	1	0
-- 2	6	like	1	0
-- 1	2	like	1	1
-- 1	3	heart	1	1
-- 1	4	like	1	1

-- reaction | n_occurences
--  date_day == 1
with base as (
select
    reaction
    , count(*) as n_occurence
    , rank() over(order by count(*) desc) as r
from
    facebook_reactions
where date_day = 1
group by 1
)
select reaction, n_occurence
from base 
where r = 1
-- revisit

---------------------------------------------------------------------------
---------------------------------------------------------------------------

-- approved friendship requests in January and February

-- facebook_friendship_requests
-- sender	receiver	date_sent	date_approved
-- 0	1	2019-01-01	
-- 0	2	2019-01-02	2019-02-02
-- 0	3	2019-01-03	2019-03-02
-- 4	5	2019-01-01	2019-01-02
-- 4	6	2019-01-01	2019-01-02
-- 4	7	2019-01-01	

-- n_approved
-- January and February extract(month from date_sent) = 01 or 02
select
    count(*) as n_approved
from
    facebook_friendship_requests
where
    extract(month from date_approved) in (1, 2)
    and date_approved is not null

---------------------------------------------------------------------------
-- User Feature Completion

-- facebook_product_features
-- feature_id	n_steps
-- 0	5
-- 1	7
-- 2	3

-- facebook_product_features_realizations
-- feature_id	user_id	step_reached	timestamp
-- 0	0	1	2019-03-11 17:15:00
-- 0	0	2	2019-03-11 17:22:00
-- 0	0	3	2019-03-11 17:25:00
-- 0	0	4	2019-03-11 17:27:00
-- 0	1	1	2019-03-11 19:51:00

-- An app has product features that help guide users through a marketing funnel. 
-- Each feature has "steps" (i.e., actions users can take) as a guide to complete the funnel. What is the average percentage of completion for each feature?
-- feature_id | avg_share_of_completion
with base as (
select
    feature_id
    ,user_id
    , max(step_reached) as max_steps
from
    facebook_product_features_realizations
group by 1,2
)
select
    f.feature_id
    , (case when max_steps is null then 0 else round(avg(max_steps) / n_steps*100,2) end) as avg_share_of_completion
from
    facebook_product_features f
    left join base b on b.feature_id = f.feature_id
group by 1
--revisit

---------------------------------------------------------------------------
-- Popular Posts

-- The column 'perc_viewed' in the table 'post_views' denotes the percentage of the session duration time the user spent viewing a post. 
-- Using it, calculate the total time that each post was viewed by users. Output post ID and the total viewing time in seconds, 
-- but only for posts with a total viewing time of over 5 seconds.

-- user_sessions
-- session_id	user_id	session_starttime	session_endtime	platform
-- 1	U1	2020-01-01 12:14:28	2020-01-01 12:16:08	Windows
-- 2	U1	2020-01-01 18:23:50	2020-01-01 18:24:00	Windows
-- 3	U1	2020-01-01 08:15:00	2020-01-01 08:20:00	IPhone
-- 4	U2	2020-01-01 10:53:10	2020-01-01 10:53:30	IPhone
-- 5	U2	2020-01-01 18:25:14	2020-01-01 18:27:53	IPhone

-- post_views
-- session_id	post_id	perc_viewed
-- 1	1	2
-- 1	2	4
-- 1	3	1
-- 2	1	20
-- 2	2	10
-- 2	3	10
-- 2	4	21
-- 3	2	1
-- 3	4	1
-- 4	2	50
-- 4	3	10
-- 6	2	2
-- 8	2	5
-- 8	3	2.5

-- post_id | total_viewtime in sec
-- TIME_TO_SEC(TIMEDIFF(session_endtime,session_starttime))*perc_viewed
--    UNIX_TIMESTAMP(session_endtime)  

select
    p.post_id
    ,SUM((UNIX_TIMESTAMP(session_endtime) - UNIX_TIMESTAMP(session_starttime))*perc_viewed/100) as total_viewtime
from 
    post_views p
    join user_sessions s on p.session_id = s.session_id
group by 1 having total_viewtime > 5.0
-- revisit

---------------------------------------------------------------------------
-- Algorithm Performance

-- Meta/Facebook is developing a search algorithm that will allow users to search through their post history. You have been assigned to evaluate the performance of this algorithm.
-- We have a table with the user's search term, search result positions, and whether or not the user clicked on the search result.
-- Write a query that assigns ratings to the searches in the following way:
-- •	If the search was not clicked for any term, assign the search with rating=1
-- •	If the search was clicked but the top position of clicked terms was outside the top 3 positions, assign the search a rating=2
-- •	If the search was clicked and the top position of a clicked term was in the top 3 positions, assign the search a rating=3
-- As a search ID can contain more than one search term, select the highest rating for that search ID. Output the search ID and its highest rating.

-- Example: The search_id 1 was clicked (clicked = 1) and its position is outside of the top 3 positions (search_results_position = 5), therefore its rating is 2.

-- fb_search_events
-- search_id	search_term	clicked	search_results_position
-- 1	rabbit	1	5
-- 2	airline	1	4
-- 2	quality	1	5
-- 3	hotel	1	1
-- 3	scandal	1	4

-- search_id | max_rating
-- logic not clicked for any -> 1, clicked and outside 3 -> 2, clicked and inside 3 -> 3
-- max(rating) by search_id for more than one search term
with base as (
select
    search_id
    ,(case 
        when clicked = 1 and search_results_position > 3 then 2
        when clicked = 1 and search_results_position <= 3 then 3
        when clicked = 0 then 1
    end) as rating
from
    fb_search_events
)
select
  search_id
  ,max(rating) as max_rating
from
    base
group by 1


---------------------------------------------------------------------------
-- Users By Average Session Time

-- Calculate each user's average session time. A session is defined as the time difference between a 
-- page_load and page_exit. For simplicity, assume a user has only 1 session per day and if there are multiple 
-- of the same events on that day, consider only the latest page_load and earliest page_exit, with an obvious 
-- restriction that load time event should happen before exit time event . Output the user_id and their average session time.

-- facebook_web_log
-- user_id	timestamp	action
-- 0	2019-04-25 13:30:15	page_load
-- 0	2019-04-25 13:30:18	page_load
-- 0	2019-04-25 13:30:40	scroll_down
-- 0	2019-04-25 13:30:45	scroll_up
-- 0	2019-04-25 13:31:10	scroll_down

-- user_id | avg
-- session_time = page_exit - page_load
-- avg per user
-- page_load < page_exit
-- min(page_exit) and max(page_load) by user, date

with base_slice as (
select
    user_id
    ,date(timestamp) as date
    ,max(case when action = 'page_load' then timestamp else null end) as start
    ,min(case when action = 'page_exit' then timestamp else null end) as end
from 
    facebook_web_log
where
    action in ('page_load', 'page_exit')
group by 1,2
)

select
    user_id
    , avg(TIMESTAMPDIFF(SECOND,start,end)) as avg
from
    base_slice
group by 1 having avg is not null
-- revisit

---------------------------------------------------------------------------
-- Acceptance Rate By Date
-- What is the overall friend acceptance rate by date? 

-- fb_friend_requests
-- user_id_sender	user_id_receiver	date	action
-- ad4943sdz	948ksx123d	2020-01-04	sent
-- ad4943sdz	948ksx123d	2020-01-06	accepted
-- dfdfxf9483	9djjjd9283	2020-01-04	sent
-- dfdfxf9483	9djjjd9283	2020-01-15	accepted
-- ffdfff4234234	lpjzjdi4949	2020-01-06	sent

-- date (request sent) | percentage_acceptance
-- action = sent
with base_slice as (
select
    user_id_sender -- note to slice data by user to get the sent date
    ,min(date) as sent_date -- minimum date as we are interested in the first sent date
    ,count(case when action = 'sent' then user_id_sender end) as n_sent
    ,count(case when action = 'accepted' then user_id_sender end) as n_acc
from
    fb_friend_requests
group by 1
)
select sent_date as date, sum(n_acc)/sum(n_sent) as percentage_acceptance
from base_slice
group by 1
order by 1
-- revisit

---------------------------------------------------------------------------
-- Premium Accounts
-- You are given a dataset that provides the number of active users per day per premium account. A premium account will have an entry for every day that it’s premium. 
-- However, a premium account may be temporarily discounted and considered not paid, this is indicated by a value of 0 in the final_price column for a certain day. 
-- Find out how many premium accounts that are paid on any given day are still premium and paid 7 days later.

-- Output the date, the number of premium and paid accounts on that day, and the number of how many of these accounts are still premium and paid 7 days later. 
-- Since you are only given data for a 14 days period, only include the first 7 available dates in your output.

-- premium_accounts_by_day
-- account_id	entry_date	users_visited_7d	final_price	plan_size
-- A01	2022-02-07	1	100	10
-- A03	2022-02-07	30	400	50
-- A01	2022-02-08	3	100	10
-- A03	2022-02-08	39	400	50
-- A05	2022-02-08	14	400	50


SELECT a.entry_date,
       count(a.account_id) premium_paid_accounts,
       count(b.account_id) premium_paid_accounts_after_7d
FROM 
    premium_accounts_by_day a
    LEFT JOIN premium_accounts_by_day b -- note the self join to get the 7 day later data
            ON a.account_id = b.account_id
                AND datediff(b.entry_date, a.entry_date) = 7
                AND b.final_price > 0
WHERE a.final_price > 0
GROUP BY 1
ORDER BY 1
LIMIT 7

---------------------------------------------------------------------------
-- Total Conversation Threads
-- You are given the table messenger_sends. Find the total number of unique conversation threads.
-- Note: In some entries, the receiver_id and sender_id are switched from the initial message. These entries should be treated as part of the same thread.

-- messenger_sends
-- id|sender_id|receiver_id

SELECT COUNT(DISTINCT 
    LEAST(sender_id, receiver_id), -- LEAST function takes two values and returns the smaller of the two
    GREATEST(sender_id, receiver_id) -- GREATEST function takes two values and returns the larger of the two
) AS total_conv_threads
FROM messenger_sends
-- Together, the LEAST and GREATEST functions are used to create a unique combination of the sender_id and receiver_id for each row in the table, regardless 
-- of whether the sender_id or receiver_id is larger. Since we know that the receiver_id and sender_id have to be unique because you can’t have a conversation 
-- with yourself - this trick gives us the ability to return the same value if the sender and receiver are reversed.
-- The LEAST and GREATEST functions are applied to each row in the table to create a unique combination of the sender_id and receiver_id. 


with base_slice as (
    select id, sender_id, receiver_id
    from messenger_sends
    UNION
    select id, receiver_id as sender_id, sender_id as receiver_id
    from messenger_sends
)
select count(distinct sender_id, receiver_id) as total_conv_threads
from base_slice
where sender_id > receiver_id


---------------------------------------------------------------------------
-- Closed Accounts

-- Get the percentage of accounts that were active on December 31st, 2019, and closed on January 1st, 2020, over the total number of accounts that were active on December 31st.
-- Each account has only one daily record indicating its status at the end of the day.

-- account_status
-- account_id|date|status

with den as (
    select count(account_id) as den from account_status
    where date = '2019-12-31' and status = 'open'
), num as (
    select count(a.account_id) as num 
    from 
        account_status a
        join account_status b using(account_id) -- note the self join to get the status on 1st Jan
    where 
        a.date = '2019-12-31' and a.status = 'open'
        and b.date = '2020-01-01' and b.status = 'closed'
)
select (num/den) as percentage_closed from den, num

---------------------------------------------------------------------------

---------------------------------------------------------------------------







--##########################################################################
--                          Hard
--##########################################################################




---------------------------------------------------------------------------
-- What is distribution on actions per post??
-- Calculate the distribution of actions on posts. Order by actions asc.

-- post_id	user_id	action_datetime	reaction_type
-- 16	66	2022-08-14 16:43:49	comment
-- 18	10	2022-11-25 23:42:30	share
-- 20	41	2022-03-17 15:14:36	comment
-- 15	26	2022-12-19 18:41:47	share
-- 39	60	2022-07-29 09:57:39	like

with base as (
  SELECT
    post_id
    , count(*) as post_actions
  FROM
    fb_posts_actions
  GROUP BY 1
)

SELECT
  post_actions
  , count(*) as no_instances
FROM
  base
GROUP BY 1
ORDER BY 1 ASC

---------------------------------------------------------------------------
-- Comments Distribution

-- Write a query to calculate the distribution of comments by the count of users that joined Meta/Facebook between 2018 and 2020, for the month of January 2020.
-- The output should contain a count of comments and the corresponding number of users that made that number of comments in Jan-2020. 
-- For example, you'll be counting how many users made 1 comment, 2 comments, 3 comments, 4 comments, etc in Jan-2020. 
-- Your left column in the output will be the number of comments while your right column in the output will be the number of users. 
-- Sort the output from the least number of comments to highest.
-- To add some complexity, there might be a bug where an user post is dated before the user join date. You'll want to remove these posts from the result.

-- fb_users
-- id	name	joined_at	city_id	device
-- 4	Ashley Sparks	2020-06-30	63	2185
-- 8	Zachary Tucker	2018-02-18	78	3900
-- 9	Caitlin Carpenter	2020-07-23	60	8592
-- 18	Wanda Ramirez	2018-09-28	55	7904
-- 21	Tonya Johnson	2019-12-02	62	4816

-- fb_comments
-- user_id	body	created_at
-- 89	Wrong set challenge guess college as position.	2020-01-16
-- 33	Interest always door health military bag. Store smile factor player goal detail TV loss.	2019-12-31
-- 34	Physical along born key leader various. Forward box soldier join.	2020-01-08
-- 46	Kid must energy south behind hold.Research common long state get at issue. Weight technology live plant. His size approach loss.	2019-12-29

-- comment_cnt | user_cnt
-- joined_at between '2018-01-01' and '2020-12-31'
--      created_at between '2020-01-01' and '2020-31-01'
-- created_at >= joined_at
-- order by comment_cnt

with base as (
select
    c.user_id
    , count(*) as comment_cnt
from
    fb_comments c
    join fb_users u on c.user_id = u.id and c.created_at >= u.joined_at
where
    c.created_at between '2020-01-01' and '2020-01-31'
    and u.joined_at between '2018-01-01' and '2020-12-31'
group by 1
)
select
   comment_cnt
   , count(user_id) as user_cnt
from
    base
group by 1
order by 1
-- revisit

---------------------------------------------------------------------------
-- The CMO is interested in understanding how the sales of different product families are affected by promotional campaigns. 
-- To do so, for each product family, show the total number of units sold, as well as the percentage of units sold that had a 
-- valid promotion among total units sold. If there are NULLS in the result, replace them with zeroes. 
-- Promotion is valid if it's not empty and it's contained inside promotions table.

-- Tables: facebook_products, facebook_sales_promotions, facebook_sales
-- product_id	product_class	brand_name	is_low_fat	is_recyclable	product_category	product_family
-- 1	ACCESSORIES	Fort West	N	N	3	GADGET
-- 2	DRINK	Fort West	N	Y	2	CONSUMABLE
-- 3	FOOD	Fort West	Y	N	1	CONSUMABLE
-- 4	DRINK	Golden	Y	Y	3	CONSUMABLE
-- 5	FOOD	Golden	Y	N	2	CONSUMABLE
-- 6	FOOD	Lucky Joe	N	Y	3	CONSUMABLE
-- 7	ELECTRONICS	Lucky Joe	N	Y	2	GADGET
-- 8	FURNITURE	Lucky Joe	N	Y	3	GADGET
-- 9	ELECTRONICS	Lucky Joe	N	Y	2	GADGET
-- 10	FURNITURE	American Home	N	Y	2	GADGET
-- 11	FURNITURE	American Home	N	Y	3	GADGET
-- 12	ELECTRONICS	American Home	N	Y	3	ACCESSORY

-- promotion_id	start_date	end_date	media_type	cost
-- 1	2022-04-01	2022-04-07	Internet	25000
-- 2	2022-05-01	2022-05-02	Broadcast	14000
-- 3	2022-05-24	2022-06-01	Print	20000
-- 4	2022-06-05	2022-06-10	Broadcast	18000

-- product_id	promotion_id	cost_in_dollars	customer_id	date	units_sold
-- 1	1	2	1	2022-04-01	4
-- 3	3	6	3	2022-05-24	6
-- 1	2	2	10	2022-05-01	3
-- 1	2	3	2	2022-05-01	9
-- 2	2	10	2	2022-05-01	1
-- 9	3	1	2	2022-05-31	5
-- 6	1	4	1	2022-04-07	8
-- 6	2	2	1	2022-05-01	10
-- 3	3	5	1	2022-05-25	4
-- 3	3	6	2	2022-05-25	6
-- 3	3	7	3	2022-05-25	7
-- 2	2	12	3	2022-05-01	1
-- 8	2	4	3	2022-05-01	4
-- 9	1	1	10	2022-04-07	2
-- 9	5	2	3	2022-04-06	20
-- 10	1	3	2	2022-04-07	4
-- 10	1	3	1	2022-04-01	5
-- 3	1	6	1	2022-04-02	10
-- 2	1	10	10	2022-04-04	8
-- 2	1	11	3	2022-04-05	6
-- 4	2	2	2	2022-05-02	7
-- 5	2	8	1	2022-05-02	7
-- 2	3	13	1	2022-05-30	3
-- 1	1	2	2	2022-04-07	3
-- 10	2	2	3	2022-05-02	9
-- 11	1	5	1	2022-04-03	9
-- 5	1	7	10	2022-04-02	9
-- 5	4	8	1	2022-06-06	8
-- 1	1	2	2	2022-04-02	9
-- 5	2	8	15	2022-05-01	2


-- product_family | units_sold | perc_with_valid_promotion
with all_sales as (
select
    product_id
    , sum(units_sold) as units_sold
    , sum(case when p.promotion_id is not null then units_sold end) as p_units_sold
from
    facebook_sales s
    left join facebook_sales_promotions p on s.promotion_id=p.promotion_id
group by 1
)
select 
    product_family
    , COALESCE(sum(units_sold),0) as units_sold
    , COALESCE(sum(p_units_sold),0) / COALESCE(sum(units_sold),1)*100 as perc_with_valid_promotion 
from 
    facebook_products p
    left join all_sales a on p.product_id = a.product_id
group by 1

---------------------------------------------------------------------------
-- Rank Variance Per Country

-- Which countries have risen in the rankings based on the number of comments between Dec 2019 vs Jan 2020? Hint: Avoid gaps between ranks when ranking countries.

-- fb_comments_count
-- user_id	created_at	number_of_comments
-- 18	2019-12-29	1
-- 25	2019-12-21	1
-- 78	2020-01-04	1
-- 37	2020-02-01	1
-- 41	2019-12-23	1

-- fb_active_users
-- user_id	name	status	country
-- 33	Amanda Leon	open	Australia
-- 27	Jessica Farrell	open	Luxembourg
-- 18	Wanda Ramirez	open	USA
-- 50	Samuel Miller	closed	Brazil
-- 16	Jacob York	open	Australia

-- rank() based on number_of_comments
-- created_at between '2019-12-01' and '2019-12-31'
-- created_at between '2020-01-01' and '2020-01-31'
-- country | r_dec | r_jan => r_jan > r_dec

with base as (
select c.user_id,c.created_at,c.number_of_comments,u.country
from 
    fb_comments_count c
    join fb_active_users u on c.user_id = u.user_id
where
    created_at between '2019-12-01' and '2020-01-31'
    and country is not null
)
, dec_rank as (
select
    country
    ,dense_rank() over(order by sum(number_of_comments) desc) as r_dec
from base
where created_at between '2019-12-01' and '2019-12-31'
group by 1
)
, jan_rank as (
select
    country
    ,dense_rank() over(order by sum(number_of_comments) desc) as r_jan
from base
where created_at between '2020-01-01' and '2020-01-31'
group by 1
)
select
    j.country -- note we want the country from jan_rank
from
    jan_rank j
    left join dec_rank d on d.country = j.country -- left join as new countries in jan_rank, but not in dec_rank
where r_jan < r_dec or d.country is null -- rank in desc order so < comparision. country null check for dec_rank for new countries in jan_rank
-- revisit

---------------------------------------------------------------------------
-- Cum Sum Energy Consumption

-- Calculate the running total (i.e., cumulative sum) energy consumption of the Meta/Facebook data centers in all 3 continents by the date. 
-- Output the date, running total energy consumption, and running total percentage rounded to the nearest whole number.

-- date | cumulative_total_energy | percentage_of_total_energy
-- date | eu,na,asia consumption | running_total

-- fb_eu_energy | fb_na_energy | fb_asia_energy
-- date | consumption 

with base_slice as (
    select * from fb_eu_energy
    UNION ALL
    select * from fb_na_energy
    UNION ALL
    select * from fb_asia_energy
)

select distinct -- note the use of distinct to remove duplicates as over clause is applied to each row
    date
    ,sum(consumption) over(order by date) as total_consumption
    ,round(sum(consumption) over(order by date) / (select sum(consumption) from base_slice) * 100,0) as cumulative_total_energy
from base_slice
-- revisit

---------------------------------------------------------------------------
-- Popularity Percentage
-- the total number of friends the user has divided by the total number of users on the platform

-- facebook_friends
-- user1	user2
-- 2	1
-- 1	3
-- 4	1
-- 1	5

--  user1 | popularity_percent
-- 100* n_friends / n_users for each user
-- order by user1
with base_slice as (
    select user1, user2 from facebook_friends
    UNION
    select user2 as user1, user1 as user2 from facebook_friends
)
select
    user1
    , count(distinct user2) / (select count(distinct user1) from base_slice) *100 as popularity_percent -- note the use of subquery to get the total number of users
from
    base_slice
group by 1
order by 1
-- revisit

---------------------------------------------------------------------------
-- Time Between Two Events
-- Meta/Facebook's web logs capture every action from users starting from page loading to page scrolling. 
-- Find the user with the least amount of time between a page load and their first scroll down. 

-- facebook_web_log
-- user_id	timestamp	action
-- 0	2019-04-25 13:30:15	page_load
-- 0	2019-04-25 13:30:18	page_load
-- 0	2019-04-25 13:30:40	scroll_down
-- 0	2019-04-25 13:30:45	scroll_up

-- user_id | load_time | scroll_time | duration
-- duration per user, day is ts diff betwen min(page_load) ts and min(scroll_down) ts
-- order by timestamp
-- min(duration) user

with page_loads as (
    select user_id, timestamp load_time
    from facebook_web_log
    where action = 'page_load'
),
scroll_downs as (
    select user_id, timestamp scroll_down_time
    from facebook_web_log
    where action = 'scroll_down'
),
diff as (
select 
    p.user_id, load_time,  scroll_down_time, timestampdiff(second, load_time, scroll_down_time) diff
from 
    page_loads p
    join scroll_downs s
        on p.user_id = s.user_id
            and s.scroll_down_time >= p.load_time
)
select
    user_id, load_time, scroll_down_time, time_format(diff, '%H:%i:%s') diff
from diff
where diff = (select min(diff) from diff)
-- revisit

---------------------------------------------------------------------------
-- Average Time Between Steps
-- Find the average time (in seconds), per product, that needed to progress between steps. You can ignore products that were never used. Output the feature id and the average time.

-- facebook_product_features_realizations
-- feature_id	user_id	step_reached	timestamp
-- 0	0	1	2019-03-11 17:15:00
-- 0	0	2	2019-03-11 17:22:00
-- 0	0	3	2019-03-11 17:25:00
-- 0	0	4	2019-03-11 17:27:00
-- 0	1	1	2019-03-11 19:51:00

-- find time taken for each user for each step they reached
-- feature_id | AVG(avg_elapsed_time)
with base_slice as (
select
    feature_id
    ,user_id
    ,timestampdiff(second, LAG(timestamp) OVER (partition by feature_id, user_id order by step_reached), timestamp) as elapsed_time
from 
    facebook_product_features_realizations
)
, feature_user_avg as (
    select feature_id, user_id, avg(elapsed_time) as avg_elapsed_time
    from base_slice
    where elapsed_time is not null
    group by 1,2
)
select feature_id, avg(avg_elapsed_time) as avg_elapsed_time 
from feature_user_avg
group by 1
-- revisit

---------------------------------------------------------------------------
-- Fans vs Opposition

-- Meta/Facebook is quite keen on pushing their new programming language Hack to all their offices. 
-- They ran a survey to quantify the popularity of the language and send it to their employees. 
-- To promote Hack they have decided to pair developers which love Hack with the ones who hate it so the fans can convert the opposition. 
-- Their pair criteria is to match the biggest fan with biggest opposition, second biggest fan with second biggest opposition, and so on. 

-- Write a query which returns this pairing. Output employee ids of paired employees. Sort users with the same popularity value by id in ascending order.
-- Duplicates in pairings can be left in the solution. For example, (2, 3) and (3, 2) should both be in the solution.

-- facebook_hack_survey
-- employee_id	age	gender	popularity
-- 0	24	M	6
-- 1	31	F	4
-- 2	29	F	0
-- 3	33	M	7
-- 4	36	F	6

-- popularity range 0 to 9. assume 9 being the highest 0 lowest
-- we can pair popularity by (0,9), (1,8), (2,7) and so on
-- we can order popularity and join with reverse order
-- pair employee_id based on above pair
-- employee_fan_id | employee_opposition_id
with opposition as (
select employee_id, row_number() over(order by popularity asc, employee_id asc) as r -- trick
from facebook_hack_survey
)
, fan as (
select employee_id, row_number() over(order by popularity desc, employee_id asc) as r -- trick
from facebook_hack_survey
)
select 
    f.employee_id as employee_fan_id
    ,o.employee_id as employee_opposition_id
from 
    opposition o 
    join fan f on o.r = f.r -- note the use of row_number() to pair employees with the above trick of ordering by popularity and employee_id
-- revisit
---------------------------------------------------------------------------
-- Retention Rate

-- Find the monthly retention rate of users for each account separately for Dec 2020 and Jan 2021. 
-- Retention rate is the percentage of active users an account retains over a given period of time. 
-- In this case, assume the user is retained if he/she stays with the app in any future months. 
-- For example, if a user was active in Dec 2020 and has activity in any future month, consider them retained for Dec. 
-- You can assume all accounts are present in Dec 2020 and Jan 2021. 
-- Your output should have the account ID and the Jan 2021 retention rate divided by Dec 2020 retention rate.

-- sf_events
-- date	account_id	user_id
-- 2021-01-01	A1	U1
-- 2021-01-01	A1	U2
-- 2021-01-06	A1	U3
-- 2021-01-02	A1	U1
-- 2020-12-24	A1	U2

with base_slice as (
select 
    user_id
    ,account_id
    ,min(date) as first_date
    ,max(date) as last_date
from sf_events
group by 1,2
)
, retention as (
select 
    *
    ,case when date_format(last_date,'%Y-%m') > '2020-12' then 1 else 0 end dec_retention
    ,case when date_format(last_date,'%Y-%m') > '2021-01' then 1 else 0 end jan_retention
from base_slice
where date_format(first_date, '%Y-%m') = '2020-12' 
)
select
    account_id, 
    round(sum(jan_retention)/sum(dec_retention)) as pct_retention
from retention
group by 1
-- revisit
---------------------------------------------------------------------------
-- Views Per Keyword
-- Create a report showing how many views each keyword has. Output the keyword and the total views, and order records with highest view count first.

-- facebook_posts
-- post_id	poster	post_text	post_keywords	post_date
-- 0	2	The Lakers game from last night was great.	[basketball,lakers,nba]	2019-01-01
-- 1	1	Lebron James is top class.	[basketball,lebron_james,nba]	2019-01-02
-- 2	2	Asparagus tastes OK.	[asparagus,food]	2019-01-01

-- facebook_post_views
-- post_id	viewer_id
-- 4	0
-- 4	1
-- 4	2
-- 5	0
-- 5	1

-- post_keywords array
-- keyword | total_views

with recursive num(n) as -- note the use of recursive cte to generate numbers from 1 to 20. it is used to split the array
(
    select 1
    union all
    select n+1 from num where n<=20
) 
, processed_keywords as (
select 
    viewer_id
    ,replace(
            replace(
                replace(post_keywords, "[", ""), -- replace [ and ] with empty string
            "]", ""),
        "#", "") as post_keyword -- replace # with empty string
from 
    facebook_posts p
    left join facebook_post_views v on p.post_id = v.post_id 
)
select 
    substring_index(substring_index(post_keyword, ",", n), ",", -1) as keyword -- note the use of substring_index to split the array. -1 is used to get the last element
    ,sum(case when viewer_id is not null then 1 else 0 end) as total_views
from 
    processed_keywords
    join num on n<=char_length(post_keyword) - char_length(replace(post_keyword, ",", "")) + 1 -- note the use of num to split the array. join condition is based on the number of , in the array
group by 1
order by 2 desc

---------------------------------------------------------------------------
-- Common Interests Amongst Users

-- Count the subpopulations across datasets. Assume that a subpopulation is a group of users sharing a common interest (ex: Basketball, Food). 
-- Output the percentage of overlapping interests for two posters along with those poster's IDs. 
-- Calculate the percentage from the number of poster's interests. The poster column in the dataset refers to the user that posted the comment.

-- The problem is asking to find the percentage of overlapping interests between two posters. The interests are represented as keywords in the 'post_keywords' column. 
-- The keywords are in a list format within each row, so we need to split them into individual words.

-- Start by creating a Common Table Expression (CTE) to clean the 'post_keywords' column by removing the "[" and "]" characters. 
-- Also, calculate the maximum number of words in each row. This will be used later to split the keywords into individual words. 

-- Now, create another CTE to split the keywords into individual words. This is done using a recursive query. 
-- After that, join the two CTEs on the condition that the posters are not the same and the split words are the same. 
-- This will give us the overlapping interests. Finally, calculate the percentage of overlapping interests and filter out the ones with zero overlap.

--Table cte1 to remove "[" and "]" character and count max words in each row
with recursive
cte1 as (   
    select 
        *,
        replace(replace(post_keywords, "[", ""), "]", "") as keywords,
        length(post_keywords) - length(replace(post_keywords, ",", "")) + 1 as max_word_count
    from facebook_posts 
)
-- Recursive table cte2 to sieve out columns with multiple words into multiple rows with single word each
, cte2 as (  
    select  #Anchor member
        poster,
        keywords,
        substring_index(substring_index(keywords, ",", max_word_count), ",", -1) as split_word,
        max_word_count
    from cte1 
    union all
    select  #Recursive member
        poster,
        keywords,
        substring_index(substring_index(keywords, ",", max_word_count - 1), ",", -1) as split_word,
        max_word_count - 1
    from cte2
    where max_word_count > 1    
) -- Terminating member

-- Final view to calculate words that are overlapping between two different posters
select 
    table1.poster as p1,
    table2.poster as p2,
    count(table2.split_word) / count(table1.split_word) as overlap
from 
    cte2 as table1
    left join cte2 as table2 
            on table1.poster <> table2.poster 
            and table1.split_word = table2.split_word
group by p1
having count(table2.split_word) / count(table1.split_word) > 0
order by p1 asc, p2 asc

---------------------------------------------------------------------------


-- Provided a table with user id and the dates they visited the platform, find the top 3 users with the longest continuous streak of visiting the platform as of August 10, 2022. Output the user ID and the length of the streak.
-- In case of a tie, display all users with the top three longest streaks.

-- user_id|date_visited|streak_start|streak_grp
-- u001	2022-08-01	1	1
-- u001	2022-08-03	1	2
-- u001	2022-08-04	0	2
-- u001	2022-08-05	0	2
-- u001	2022-08-07	1	3
-- u001	2022-08-08	0	3
-- u001	2022-08-09	0	3
-- u001	2022-08-10	0	3

-- u002	2022-08-03	1	1
-- u002	2022-08-08	1	2
-- u002	2022-08-10	1	3

-- u003	2022-08-02	1	1
-- u003	2022-08-06	1	2
-- u003	2022-08-07	0	2
-- u003	2022-08-08	0	2
-- u003	2022-08-09	0	2
-- u003	2022-08-10	0	2

-- u004	2022-08-01	1	1
-- u004	2022-08-02	0	1
-- u004	2022-08-03	0	1
-- u004	2022-08-04	0	1
-- u004	2022-08-05	0	1
-- u004	2022-08-06	0	1
-- u004	2022-08-07	0	1
-- u004	2022-08-08	0	1
-- u004	2022-08-09	0	1
-- u004	2022-08-10	0	1

-- u005	2022-08-01	1	1
-- u005	2022-08-02	0	1
-- u005	2022-08-03	0	1
-- u005	2022-08-04	0	1
-- u005	2022-08-05	0	1
-- u005	2022-08-06	0	1
-- u005	2022-08-07	0	1
-- u005	2022-08-08	0	1
-- u005	2022-08-09	0	1
-- u005	2022-08-10	0	1

-- u006	2022-08-05	1	1
-- u006	2022-08-06	0	1
-- u006	2022-08-07	0	1
-- u006	2022-08-08	0	1

-- Filter data before aug 10, 2022 with unique user date visit
with base_slice as (
    select distinct user_id, date_visited 
    from user_streaks
    where date_visited <= '2022-08-10'
)
-- create streak start column by subtracting date visted and lag(1). If 0, then streak continues else discontinued
, streak_start as (
select
    user_id
    ,date_visited
    ,case when timestampdiff(day,LAG(date_visited) over(partition by user_id order by date_visited),date_visited) = 1 then 0 else 1 end as streak_start
from base_slice
)
-- create the streak group number with sum of streak start. it is the continuous streak by user
, streak_group as (
select
    user_id
    ,streak_start
    ,sum(streak_start) over(partition by user_id order by date_visited) as streak_grp 
from streak_start
)
-- aggregate the user, streak group count
, agg_streak as (
select 
    user_id, streak_grp, count(*) as streak_length
from streak_group
group by 1,2
)
-- select the user based on top streak length
select user_id, max(streak_length) as streak_length
from agg_streak
group by 1
order by 2 desc
limit 3 -- top three users


-- *** Variant of the above problem *** ---
-- find the percentage of users that had at least one seven-day streak of visiting the same URL.

-- events
-- user_id | url | created_at

with base as (
    select distinct user_id, url, created_at from events -- note addition of url
)
, streak_start as (
    select user_id, url, created_at -- note addition of url
        ,(case when datediff(created_at, LAG(created_at) over(partition by user_id, url order by created_at)) = 1 then 0 else 1 end) as streak_start
    from base
)
, streak_group as (
    select user_id, url, streak_start -- note addition of url
        ,SUM(streak_start) over(partition by user_id,url order by created_at) as streak_group
    from streak_start
)
, agg_streak as (
    select user_id, url, streak_group, count(*) as streak_length -- note addition of url
    from streak_group
    group by 1,2,3
)
select -- count distinct users with streak length of 7
    coalesce(round(count(distinct case when streak_length = 7 then user_id end) / count(distinct user_id),2),0) as precent_of_users
from agg_streak