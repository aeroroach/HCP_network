# HCP Network Graph

![alt text](https://user-images.githubusercontent.com/24812908/176720814-2bcc1fbc-4977-4a45-bdea-383601203173.png)

Utilizing HCP data profile to infer the relationship of each Health Care Providers

The interesting approach of this project is listed below.

* Utilizing existing data to infer the relationship as much as possible
  * Meeting event
  * Secondary relationship from similar specialty in similar hospital
  * Assign weights for the strenghts of the relation
* Utilize R to connect with AWS Redshift directly
* Using `dtplyr` for efficient and fast data wrangling (Processing time reduce from `dplyr` from 5 minutes to 3 seconds)
* Using `tidygraph` for calculating centrality locally in each group by using `morph`
* Centrality score that has been used is google_pagerank and betweeness due to the nature of data
* Visualize the network by `visNetwork` for the sake of beauty and interactively fluid
* Output the graph with Shiny for interactive and ease of use for business users
