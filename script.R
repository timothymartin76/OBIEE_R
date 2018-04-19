## Sys.setenv(JAVA_HOME='C:\\Program Files\\Java\\jdk1.6.0_45')

library(RJDBC)
library(raster)
library(ggplot2)
library(tidyr)
library(ggmap)
library(dplyr)
library(maps)
library(plotly)

setwd("C:/PostgreSQL_Docs/bijdbc")

drv <- JDBC("oracle.bi.jdbc.AnaJdbcDriver","bijdbc.jar")
conn <- dbConnect(drv, "jdbc:oraclebi://sprdorabiw-hq.buildings.nycnet:9703/", "username", "password")

## dbListTables(conn)

## dbListFields(conn,"DOB_BIS_LICENSE")

## dbGetQuery(conn, "select * Milestone")  

## grab logical SQL from OBIEE and find/replace " with \" 

x<- dbGetQuery(conn, "SELECT \"- Permit Key Fields\".\"Job Number\" saw_0, \"- Permit Key Fields\".\"Borough Name\" saw_1, \"- Permit Facts\".\"Count Permits\" saw_2, \"- First Permit Date (Q Date)\".\"First Permit Date\" saw_3, MAX(\"- Permit Expiration Date\".D_DATE) saw_4, \"- 15 - Construction Equipment\".\"Sidewalk Shed/Linear Feet\" saw_5, \"- 15 - Construction Equipment\".\"Construction Material\" saw_6, \"- 15 - Construction Equipment\".\"BSA/MEA Approval Number\" saw_7, \"- Key Job Information (Job Number and Status)\".\"Current Job Status\" saw_8, \"- 1- Location Information\".\"BIN Number\" saw_9, \"- Key Segment\".\"Latitude Point\" saw_10, \"- Key Segment\".\"Longitude Point\" saw_11, \"- Key Segment\".\"House Number\" saw_12, \"- Key Segment\".\"Street Name\" saw_13 FROM \"DOB - Job Filings, v 3.0\" WHERE (\"- Permit Key Fields\".\"Borough Name\" IN ('Bronx', 'Brooklyn', 'Manhattan', 'Queens', 'Staten Island')) AND ((\"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '10%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '11%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '20%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '21%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '30%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '31%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '40%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '41%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '50%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '51%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '12%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '22%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '32%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '42%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '52%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '14%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '24%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '34%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '44%' OR \"- Key Job Information (Job Number and Status)\".\"Job Number\" LIKE '54%')) AND (\"- Applicant Segment\".\"Applicant Email\" NOT LIKE '%buildings.nyc.gov%') AND (\"- Permit Key Fields\".\"Permit Sub Type\" = 'SH') AND (\"- Permit Issuance Date\".D_YEAR >= 1989) AND (\"- Key Job Information (Job Number and Status)\".\"Current Job Status\" NOT IN ('U', 'X')) AND (MAX(\"- Permit Expiration Date\".D_DATE) >=  VALUEOF(\"Today\")) AND (\"- Key Job Information (Job Number and Status)\".\"Withdrawal Description\" NOT IN ('Administrative Closure', 'Withdrawn')) AND (\"- 1- Location Information\".\"BIN Number\" NOT IN ('1813361', '1813248', '1813359', '1813360')) AND (\"- First Permit Date (Q Date)\".\"First Permit Date\" IS NOT NULL) ORDER BY saw_3")  


##change saw_3 to date format
x$saw_3<- as.Date(x$saw_3)  

##calculate date difference in days and create new field
x$Age<- difftime(x$saw_4 ,x$saw_3 , units = c("days"))


## Change column names
names(x)<- c("Job Number", "Borough", "Count.Permits", "First.Permit.Date", "Permit.Expiration.Date", "Linear.Feet", "Material", "BSA.MEA.Approval.Number", "Current.Job.Status", "BIN", "Lat", "Lon", "Street.No", "Street.Name", "Age.days")

## create address field
x$Address <- paste(x$Street.No," ",x$Street.Name)


x$Lon = as.numeric(as.character(x$Lon))
x$Lat = as.numeric(as.character(x$Lat))
x$Age.days = as.numeric(as.character(x$Age.days))



## Mapbox token
Sys.setenv('MAPBOX_TOKEN' = 'xxxxxxxxxx')

## Create map
p <- x %>%
    plot_mapbox(lat = ~Lat, lon = ~Lon, mode = 'scattermapbox', color=~Age, text=~paste(x$Address, x$Borough, 'Age (days):',round(x$Age.days,1),  sep = "<br>"), hoverinfo="text") %>%
	

	add_markers(y=~Lat, x=~Lon, color=~Age.days, colors = c("#9ecae1", "#4292c6", "#2171b5", "#08519c", "#06214A" ),size=~Age.days, marker=list(sizeref=0.5)) %>% 
	
	config(displayModeBar = F)%>% 
	
    layout(title="Active Sidewalk Sheds", mapbox = list(style='light', zoom = 12, center = list(lat = ~(40.747458), lon = ~(-73.960991))))
	
p

##push to plotly

Sys.setenv("plotly_username"="username")
Sys.setenv("plotly_api_key"="password")

##Close connection
##dbDisconnect(conn)

library(xml2)
library(httr)

## use httr package to configure proxy
set_config(use_proxy(url="url", port=8080, username="username", password="password", auth="basic"))
set_config(config(ssl_verifypeer = 0L))

api_create(p, filename = "Shed_Map")


