# library(tidyverse)

con <- DBI::dbConnect(RPostgres::Postgres(),
                 host = "awsapcimbirsp01.coaaq18eo1zb.ap-southeast-1.redshift.amazonaws.com",
                 port = 25881,
                 user = "cim_iss_prd_th_ro_user",
                 password = "CimIssPrdThRO2021",
                 dbname = "apbirsp01")


# sales <- tbl(con, sql("SELECT * FROM cim_cdm_pub.vw_f_sales_transaction"))

# DBI::dbDisconnect(con)