#  DHS_Import 1.00             Damian C Clarke                   vers:2012-09-01
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
# Syntax is: python DHS_Import dir1 dir2
#  where dir1 is the file where unzipped files should go, and dir2 the downloads
#  file on the computer.
#  In my case this looks something like:
#         python DHS_Import.py ~/database/DHS/DHS_Data ~/Descargas
#
# At the moment this does not include continuous DHS surveys (ie Peru 2004-'06)

#*******************************************************************************
# (1) Import required packages, set-up names used in urls
#*******************************************************************************
from sys import argv
import os
import urllib, urllib2
from urllib2 import urlopen, URLError, HTTPError
import re
import webbrowser, cookielib
import zipfile


script, filename1, filename2 = argv

f_surveys = open("DHS_Surveys.txt", "w")
f_surveys_stata = open("DHS_Surveys_StataUse.txt", "w")
f_countries = open("DHS_SurveyCountry.txt", "w")
h1 = 'http://www.measuredhs.com/data/dataset/'
h2a = '_Standard-DHS_'
h2b = '_Special_'
h2c = '_Standard-AIS_'
h2d = '_Continuous-DHS_'
h3= '.cfm?flag=1'
data1 = 'http://www.measuredhs.com/customcf/legacy/data/download_dataset.cfm?Filename='
data2 = '&Tp=1&Ctry_Code='

#*******************************************************************************
# (2) download zip files for each survey
#*******************************************************************************
for year in range(1985,2014):
#And loop through all countries available by application
	for line in open("DHS_Countries.txt"):
		country = line[0:-1]
		country_name = line[3:-1]
		print country + " " + str(year)
		country_code=line[0:2] #create a variable called country code (needed for url)

		#Now test if each country has a survey in each year, returning the name
		urla = h1 + line[3:-1] + h2a + str(year) + h3
		urlb = h1 + line[3:-1] + h2b + str(year) + h3
		urlc = h1 + line[3:-1] + h2c + str(year) + h3
		print(urla)

		response_a = urllib2.urlopen(urla).read()
		matches_a = re.findall('The link or bookmark is no longer valid', response_a);

		response_b = urllib2.urlopen(urlb).read()
		matches_b = re.findall('The link or bookmark is no longer valid', response_b);

		response_c = urllib2.urlopen(urlc).read()
		matches_c = re.findall('The link or bookmark is no longer valid', response_c);

		#if there is no match for missing, the country has a survey
		if len(matches_a) == 0 or len(matches_b) == 0 or len(matches_c) == 0: 
			print('%s has a DHS survey in %d' %(line[0:-1], year))
			f_countries.write(country + "\t" + str(year) + "\n")

			if len(matches_a) == 0:
				response = response_a
			elif len(matches_b) == 0:
				response = response_b
			elif len(matches_c) == 0:
				response = response_c

			#search for all stata files
			survey = response.find('dt.zip');
			while survey > -1:
				print "dt.zip found at location", survey
				#create survey name (capitalized, no spaces, for url)
				survey_name = response[survey-10:survey+10]
				surveynamelow = survey_name.strip()
				survey_name = surveynamelow.upper()
				print(survey_name)
				survey_s = survey_name[0:-4]
				recode = survey_name[2:4]
				urldata = data1 + survey_name + data2 + country_code
				print "fetching url data: %s\n" % urldata 
				webbrowser.get('firefox').open(urldata)

				# Create file listing all DHS countries, years, and the surveys
				f_surveys.write(country + "\t" + str(year) + "\t" + survey_name + "\n")
				f_surveys_stata.write(country_code + "\n" + country_name + "\n" + str(year) + "\n" + survey_s + "\n" + recode + "\n")
				# skip to next file type for given country and year
				survey=response.find('dt.zip', survey+1)
		
		else:
			print('There is no DHS survey in %s in %d' %(line[0:-1], year))

f_surveys.close()
f_surveys_stata.close()
f_countries.close()

#*******************************************************************************
# (3) Unzip folders saving .dta files in appropriate folders
#*******************************************************************************
cwd = os.getcwd()
for line in open("DHS_SurveyCountry.txt"):
	#Create folders with names of countries and years (note that here lines
	#could be removed using makedirs instead of mkdir)
	os.chdir(argv[1])	
	country = line[3:-6]
	year = line[-5:-1]
	if not os.path.isdir(country):
		os.mkdir(country)
		os.chdir(country)
		os.mkdir(year)
	if os.path.isdir(country):
		os.chdir(country)
		if not os.path.exists(year):
			os.mkdir(year)
	os.chdir(cwd)

for line in open("DHS_Surveys.txt"):
	#Record country, year, survey name, survey type, and file name
	country = line[3:-19]
	year = line[-18:-14]
	survey = line[-13:-1]
	survey_save = survey[0:-4]
	recode = line[-11:-9]
	os.chdir(cwd)
	os.chdir(argv[2])

	if os.path.isfile(survey):
		#Read in compressed zip file, uncompress, and save .dta files:
		zin = zipfile.ZipFile(survey, "r")
		for info in zin.infolist():
			fname1 = info.filename
			fname = fname1[-4:]
			fname_save = fname1[0:-5]
			print fname
			if fname == ".dta" or fname == ".DTA":
				print fname
				#read in .dta files only
				data = zin.read(fname1)
				os.chdir(cwd)
				os.chdir(argv[1])
				os.chdir(country)
				os.chdir(year)

				#Save decompressed stata files in appropriate folders
				fout = open(survey_save + ".dta", "w")
				fout.write(data)
				fout.close()
			os.chdir(cwd)
			os.chdir(argv[2])
