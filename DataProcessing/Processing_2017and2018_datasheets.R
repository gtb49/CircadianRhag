#R script from original Processing 2017 and 2018 datasheets markdown

library (readxl)
data2017<-read_excel("E:/Hahn Lab/CircadianRhag/RawData/DataSheets/2017-08-24_rhagoletis_data_sheet.xlsx", sheet = 2)
data2017
data2018<-read_excel("E:/Hahn Lab/CircadianRhag/RawData/DataSheets/2018-08-14_master_datac_2018_collection_year.xlsx", sheet = 2)
data2018

#Exploring the dimensions of the datasets. Are they formatted the same between years? 

dim(data2017) #finds 1909 obs of 47 variables
dim(data2018) #finds 3631 obs of 49 variables

#Datasheet format is different between years. What is the difference?
labels2017<-colnames(data2017)
labels2018<-colnames(data2018)
setdiff(labels2017,labels2018) #What labels are in 2017 but not 2018?

setdiff(labels2018,labels2017) #What labels are in 2018 but not 2017?

####Interpretation: 
#Apparently in 2017 both licor analyzers were used to collect respirometry data for metabolic rate analyis. Only 1 used in 2018 or else not recorded.  
#Year 2 fridge and 'SO' columns appear to be irrelevant - no data ever entered in either column
#mass_day19, purge_time_3, resp_time_3, and resp_day20 are all related to taking respirometry measures a 3rd time 
#Day 19 used on RT and some GC flies - not SO b/c in fridge by that point. 
#Will not affect main analyses - day 15 is the relevant time point. 
#Entrainment enter date is the same as eclosion date in 2017. 
#2017 does not have entrainment enter date - must be inferred from eclosion records. 

####Checking that entrainment_enter_date *does* always match eclosion in 2018: 

library(tidyverse) #to 'tidy' data
relevantdates2018<-data2018 %>%
  filter(eclosion_date > 0,
         Entrainment_enter_date > 0) #Just pulling the subset of data where those columns both have data

matched<-if_else(relevantdates2018$eclosion_date == relevantdates2018$Entrainment_enter_date,TRUE,FALSE) #if the dates are the same - TRUE, if not, FALSE
length(matched) #1018 observations went into entrainment
summary(matched)

#Of 1018 flies that eclosed and went into entrainment in 2018: 840 entrained on eclosion day, 178 began entrainment at a different age. 
#In 2018 eclosion date is _not_ equal to entrainment date (unlike in 2017)
#Will need to add this as another variable to account for delayed entrainment
#Add Column to 2017 to make dataframes match (so don't have to re-do things for the different years) 

########THIS SECTION IS WRONG DO NOT RUN
####2017 Eclosion dates - there are gaps. 

#The 2017 eclosion dates have gaps -  date only entered once and updated once it changes, so if multiple flies eclosed and entered entrainment on the same day, some will not have the relevant dates needed for analysis. 

#missingdates<-is.na(data2017$eclosion_date) #returns "true" if value = NA 
#summary(missingdates)

#: 605 animals have eclosion dates. There are 1304 cases where the value = NA
#The 2017 eclosion dates have gaps - date only entered once and updated once it changes, so if multiple flies eclosed and entered entrainment on the same day, some will not have the relevant dates needed for analysis.
#This number is needed for circadian analysis because in 2017 this date is the start of entrainment.
#Need to 'forward fill' the gaps. 

####Testing Forward-fill

#testdata2017<- data2017 %>% fill(eclosion_date) #test-filling the gaps in data entry. This does not overwrite any dates that are already entered. It just re-uses the most recent date until it runs into a spot where the data sheet starts using a new date. This matches how the data was originally done in Excel. 
#testdata2017$eclosion_date
#comparedates<-cbind(data2017$eclosion_date,testdata2017$eclosion_date)
#comparedates[1:15,]#showing the first 15 lines of data to confirm how it was filled

#Test run worked - apply to full dataset
#Need to forward fill the full 2017 data and match that to eclosion entry date column. 

#data2017<- data2017 %>% fill (eclosion_date) #applying forward fill to full dataset

#To use the same analysis code on 2017 and 2018 data, 2017 needs an 'Entrainment_entry_date' column. In 2017 this always matches eclosion date, but it needs to have the same name as 2018. Creating a new column to match 2018 format:

#Entrainment_enter_date<-data2017$eclosion_date
#data2017<-cbind(data2017, Entrainment_enter_date) #duplicating the eclosion data column in 2017 to match 2018 formatting
#colnames(data2017)(checking that it was added - it was)
#matched2017<-if_else(data2017$eclosion_date == data2017$Entrainment_enter_date, TRUE, FALSE, missing = NULL)
#summary(matched2017) #Confirming the columns are identical - they are. No returns of "FALSE"

#New column was added  - now all flies have an ecolosion date and an entrainment date. 
##################################################################################################




### Stitching 2017 and 2018 datasheets together so they can be handled with a single analysis


#cannot combine dataframes if the class of variables is different
#unequal columns isn't a problem
all_equal(data2017, data2018)

library(janitor)
compare_df_cols(data2017,data2018, return="mismatch") 

#Unfortunately there are some formatting differences in data entry between 2017 and 2018
#If these aren't matched the dataframes cannot be combined (or analyzed as a single dataset without a lot of issues)


####Going through the mismatched formats for 2017 and 2018 to fix them
#Note that different functions produce different methods of storing date/time data
  #Currently almost everything lists POSIXct, POSIXt
  #as.POSIXct will convert most data types into this format
  #strptime function will product POSIXlt which is not the same. 

#converting all 2017 columns to the appropriate format for that variable (dates to POSIXct, numbers should all be numeric etc.

data2017$Adult_death_date <-as.POSIXct(data2017$Adult_death_date, format="%Y-%m-%d") #date from character to POSIXct datetime
#USE as.POSIXct from here on
data2017$eclosion_date<-as.POSIXct(data2017$eclosion_date, format= "%Y-%m-%d")  #several dates in a row to fix
data2017$Eclosion_reference_date<-as.POSIXct(data2017$Eclosion_reference_date, format= "%Y-%m-%d")
data2017$Entrainment_enter_date<-as.POSIXct(data2017$Entrainment_enter_date, format= "%Y-%m-%d")
data2017$Free_run_entry_date<-as.POSIXct(data2017$Free_run_entry_date, format= "%Y-%m-%d")
data2017$Free_run_exit_date<-as.POSIXct(data2017$Free_run_exit_date, format= "%Y-%m-%d")
data2017$Trikinetic_exit_date<-as.POSIXct(data2017$Trikinetic_exit_date, format= "%Y-%m-%d")

data2017$treatment_day15<-strptime(data2017$treatment_day15, format = "%Y-%m-%d")

data2017$Free_run_exit_time<-parse_date_time(data2017$Free_run_exit_time, orders = "HM")


data2017$cohort_day <-as.numeric(data2017$cohort_day) #a count from character to numeric
data2017$Free_run_trik_monitor <-as.numeric(data2017$Free_run_trik_monitor)
data2017$Free_run_trik_position <-as.numeric(data2017$Free_run_trik_position)

#Correcting mismatched 2018 data class/types
data2018$purge_time_1<-parse_date_time(data2018$purge_time_1, orders= "HM")

data2018$Resp_code<-as.numeric(data2018$Resp_code)
data2018$purge1<-as.numeric(data2018$purge1)
data2018$treatment_day15<-strptime(data2018$treatment_day15, format ="%Y-%m-%d")
data2018$notes<-as.character(data2018$notes)

####Formats of 2017 and 2018 columns should be matched now. Are they?

compare_df_cols(data2017,data2018, return="mismatch")  #Should return no mismatches now. 

#Outcome: Now all the formats for 2017 and 2018 are matched. There could still be some mistakes in other columns (incorrect class) but at least they're matched now and the datasheets can be stitched together and handled as one.

#####Now I need to add year as a variable to keep track of 2017 vs 2018 samples for later analysis. 
#Adding year as a variable for 2017 samples, across all rows (each data point has a year)
length(data2017$Ind_ID)
xyear<-rep(c(2017), each=1909) #creating a vector repeating the value 2017 at 1909 times (matched to # rows)
length(xyear)
xyear
data2017<-cbind(data2017,xyear)
data2017$xyear

#Doing the same for 2018
length(data2018$Ind_ID)
xyear<-rep(c(2018),each = 3631)
length(xyear)
data2018<-cbind(data2018, xyear)
data2018$xyear

#Now that year is a variable: 
####Stitching together 2017 and 2018 so I don't have to do everything in duplicate anymore. 

alldata<-bind_rows(data2017,data2018)
alldata
length(alldata$xyear)

####All data incorporated into a single datasheet (still needs some additional processing)
#Write new datasheet to .txt file. 


library(writexl)
###### currently commented don't overwrite file - if re-run change the file name
#write_xlsx(alldata,"E:/Hahn Lab/CircadianRhag/DataProcessing/alldata.xlsx")
