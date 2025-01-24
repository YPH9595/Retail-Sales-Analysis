import requests
import csv

# API Endpoint
base_url = "https://date.nager.at/api/v3/PublicHolidays"

# List of countries and years
countries = ['FI', 'BH', 'IE', 'BR', 'US', 'IT', 'NL', 'HK', 'DE', 'CY', 'MT', 'LB', 
             'AU', 'JE', 'LT', 'IS', 'ZA', 'CH', 'EU', 'SA', 'GB', 'SE', 'AT', 'GR', 
             'IL', 'PL', 'CA', 'AE', 'NO', 'FR', 'ES', 'DK', 'BE', 'JP', 'SG', 'CZ', 'PT']
years = [2010, 2011]

output_file = "holidays.csv"

fieldnames = ["date", "name", "countryCode", "global", "types"]

all_holidays = []

# Fetch data from the API for each country and year
for country in countries:
    for year in years:
        try:
            url = f"{base_url}/{year}/{country}"
            response = requests.get(url)
            response.raise_for_status()  
            holidays = response.json()  
            for holiday in holidays:
                # Extract relevant fields
                row = {
                    "date": holiday.get("date"),
                    "name": holiday.get("name"),
                    "countryCode": holiday.get("countryCode"),
                    "global": holiday.get("global"),
                    "types": ", ".join(holiday.get("types", []))  # Convert list to string
                }
                all_holidays.append(row)

        except requests.exceptions.RequestException as e:
            print(f"Failed to fetch data for {country} in {year}: {e}")

# Save data
with open(output_file, mode="w", newline="", encoding="utf-8") as file:
    writer = csv.DictWriter(file, fieldnames=fieldnames)
    writer.writeheader()  
    writer.writerows(all_holidays)  

print(f"Holidays data has been saved to '{output_file}'.") 
