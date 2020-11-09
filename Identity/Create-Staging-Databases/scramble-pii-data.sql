-- This script scrambles members table data, addresses table data, updates phone numbers to a
-- fake number and truncates  member_actions_data, member_external_ids, active_record_audits and audits table.
-- The intent is to make a useful but safe staging database.
-- IT IS VERY VERY IMPORTANT THIS IS NEVER RUN AGAINST PRODUCTION DATABASES
-- This script takes around 3-4 hours to complete currently.

UPDATE phone_numbers set phone=’02081231234’;
TRUNCATE member_actions_data;
TRUNCATE  member_external_ids;
TRUNCATE active_record_audits;
TRUNCATE audits;

CREATE FUNCTION scramble_members() RETURNS varchar as $$
DECLARE
-- Make an array of up to 1000 first/last names that occur more than 20 times in DB.  We're avoiding unique or almost unique names then (as they'd be identifiable)
first_names text[] := array(SELECT first_name FROM
                                   (SELECT first_name,count(*) AS n FROM members GROUP BY first_name HAVING count(*) > 20 ORDER BY N DESC LIMIT 1000) AS names);
last_names text[] := array(SELECT last_name FROM
                                  (SELECT last_name,COUNT(*) AS n FROM members GROUP BY last_name HAVING count(*) > 20 ORDER BY n DESC LIMIT 1000) AS names);

BEGIN
-- Update first/last names with a random first/last name from array
-- above.  Set middle_names to null (this matches our live data) Set
-- email address to #{id}@38degreesscrambler.com other data is either
-- not used at 38degrees (gender, title) or seems safe + useful to
-- leave alone (mosaic data)
  UPDATE members SET email=concat(id, '@38degreesscrambler.com'), middle_names=null, first_name = first_names[ceil(random() * array_length(first_names,1))], last_name = last_names[ceil(random() * array_length(last_names,1))], latitude=null, longitude=null 
         WHERE email not like '%@example.com' 
         AND email not like '%38degreesscrambler.com'
         AND email not like '%@38degrees.org.uk';
  RETURN 'success';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION scramble_addresses() RETURNS VARCHAR as $$
DECLARE
-- Make an array of towns/countries/postcodes with more than 20 occurrances in our database
towns text[] := array(SELECT town FROM
                                   (SELECT town,count(*) AS n FROM addresses GROUP BY town HAVING count(*) > 20 ORDER BY N DESC LIMIT 1000) AS towns);
postcodes text[] := array(SELECT postcode FROM
                                   (SELECT postcode,count(*) AS n FROM addresses GROUP BY postcode HAVING count(*) > 20 ORDER BY N DESC LIMIT 1000) AS postcodes);
line2s text[] := array(SELECT line2 FROM
                                   (SELECT line2,count(*) AS n FROM addresses GROUP BY line2 HAVING count(*) > 20 ORDER BY N DESC LIMIT 1000) AS line2s);
                                                                      
animals text[] := array['cat','aporpoise','bat','seal','orangutan','zebra','llama','donkey','lovebird','mule','opossum','squirrel','weasel','finch','rabbit','deer','raccoon','capybara','coyote','guanaco','puppy','puma','koala','mustang','peccary','ox','iguana','sloth','mink','chicken','coati','dog','hartebeest','cougar','goat','bunny','armadillo','frog','buffalo','hog','baboon','marmoset','rooster','chinchilla','alpaca','hare','colt','mouse','fox','kangaroo','bison','ape','marten'];
roads text[] := array['Lane', 'Rd', 'Road', 'St', 'Street', 'Ln', 'Ave', 'Avenue', 'Way', 'Park'];
BEGIN

-- Update addresses with random selections from lists above.  Line1 we
-- just make up as its entirely possible to have a uniquely
-- identifying first line of address

UPDATE addresses SET
 line1=CONCAT( CEIL( RANDOM() * 120 ), ' ',animals[CEIL(RANDOM() * ARRAY_LENGTH(animals,1))], ' ', roads[CEIL(RANDOM() * ARRAY_LENGTH(roads,1))]),
         line2 = line2s[ceil(random() * array_length(line2s,1))],
         town = towns[ceil(random() * array_length(towns,1))],
         country = 'GB', -- more representative than randomly choosing as 99.99% of folks are GB
         postcode = postcodes[ceil(random() * array_length(postcodes,1))];
  RETURN 'success';
END;
$$ LANGUAGE plpgsql;
 

select scramble_members();
select scramble_addresses();
