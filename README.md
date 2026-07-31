# RZR Analytics Challenge

Associate Analyst case study. 3,021 leads sold to one advertiser (Apr to Sep 2009). The goal was to answer three questions: is lead quality trending over time, what actually drives it, and can we hit a 9.6% quality rate if the advertiser bumps CPL by 20%.

## What's in here

1. **1_Clean_dataset_from_Excel.csv** - the raw dataset cleaned up in Excel. Dropped the blank IP Address column, flagged one duplicate lead instead of deleting it, standardized CallStatus into four quality buckets, added an IsClosed flag, and parsed DebtLevel into actual numbers so it could be sorted and grouped.

2. **2_EDAusingSQL.sql** - first pass of exploration in MySQL on the cleaned data. Reproduced the 8.11% baseline quality rate and poked around at monthly trends and the candidate drivers before testing anything formally.

3. **3_Statistical_Analysis_using_Python.ipynb** - the actual significance testing, done with pandas and scipy. Used chi-square tests to check whether the patterns from the SQL step were real or just noise. This is where I confirmed the month to month trend is statistically significant (p = 0.0007), and that Debt Level is the only driver that holds up (p = 0.0062) out of everything tested.

4. **4_Dashboards_using_PowerBI.pbix** - a two page interactive dashboard built on the cleaned data. Page 1 covers the trend over time and the driver patterns, page 2 covers the path to 9.6% quality and the revenue tradeoffs between two different strategies.

## Full write-up

A complete report walking through all four steps and the final answers to each question is submitted to the provided link.
