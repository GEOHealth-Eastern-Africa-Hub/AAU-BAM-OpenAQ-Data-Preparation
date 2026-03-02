###############################################################################
# AAU BAM-1022 Data Preparation for OpenAQ Submission
#
# Institution: Addis Ababa University (AAU) - GEOHealth
# Location: Tikur Anbessa Specialized Hospital (TASH)
# Parameter: PM2.5
# Instrument: BAM-1022
#
# Format datetime into ISO 8601 format
# Framework-compliant: Non-Imputed Values export (CSV)
#
# NOTE:
# Raw data is confidential and not included in this repository.
# This repository contains only processing scripts and sample output.
###############################################################################
###############################################################################

# ---------------------------------------------------------
# 1. Load Required Libraries
# ---------------------------------------------------------
library(tidyverse)
library(lubridate)

# ---------------------------------------------------------
# 2. Read Full Dataset
# ---------------------------------------------------------
BAM <- read.csv("input/BAM_April1st2017_to_Sept30th2023.csv")

# ---------------------------------------------------------
# 3. Clean, Format & Structure According to Framework
# ---------------------------------------------------------
BAM_final <- BAM %>%
  
  # Parse datetime (original timestamps assumed Addis local time)
  mutate(
    datetime_parsed = mdy_hm(Time),
    
    # Assign the correct timezone WITHOUT shifting clock time
    datetime_addis_corrected  = force_tz(datetime_parsed,
                                         tzone = "Africa/Addis_Ababa"),
    
    # Format as ISO-8601 with explicit UTC offset (+03:00)
    datetime = sub("(\\d{2})(\\d{2})$", "\\1:\\2", format(datetime_addis_corrected, 
                                                          "%Y-%m-%dT%H:%M:%S%z")),
    
    # Framework-required metadata fields
    name          = "AddisTASHGEOHealth",
    location_code = "Addis Ababa, Tikur Anbessa Specialized Hospital (TASH), GEOHealth",
    latitude      = 9.01523,
    longitude     = 38.74291,
    duration      = 3600,                 # hourly values
    parameter     = "pm25",
    unit          = "ug/m3",
    sensor_code   = "BAM 1022",
    value         = `ConcRT.ug.m3.`
  ) %>%
  
  # Remove original/raw columns
  select(-Time, -datetime_parsed, -datetime_addis_corrected) %>%
  
  # Keep only required columns in exact framework order
  select(
    name,
    location_code,
    latitude,
    longitude,
    duration,
    parameter,
    unit,
    sensor_code,
    value,
    datetime
  ) %>%
  
  # Remove rows with missing value or datetime (non-imputed rule)
  filter(!is.na(value), !is.na(datetime))

# ---------------------------------------------------------
# 4. Uniqueness Validation
#    (datetime + parameter + value must be unique)
# ---------------------------------------------------------
duplicate_check <- BAM_final %>%
  count(datetime, parameter, value) %>%
  filter(n > 1)

if(nrow(duplicate_check) > 0){
  warning("Duplicate measurements detected based on datetime + parameter + value")
}

# ---------------------------------------------------------
# 5. Export OpenAQ-Ready CSV
# ---------------------------------------------------------
write.csv(BAM_final, file = paste0("output/", Sys.Date(),
                                   "_GEOHealth_BAM_AAU_Full_2017_2023_OpenAQ.csv"),
          row.names = FALSE, na = "")

###############################################################################
# END OF SCRIPT
###############################################################################