-- Q4. Plane Capacity Histogram -- Create a table that is, essentially, a histogram of the percentages of how full planes have been on the flights that they have made 
-- (that is, only the flights that have actually departed).

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	airline CHAR(2),
	tail_number CHAR(5),
	very_low INT,
	low INT,
	fair INT,
	normal INT,
	high INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS DepartedFlights CASCADE;
DROP VIEW IF EXISTS PassengersAboard CASCADE;
DROP VIEW IF EXISTS PassengerCapacity CASCADE;
DROP VIEW IF EXISTS combined CASCADE;
DROP VIEW IF EXISTS very_low CASCADE;
DROP VIEW IF EXISTS low CASCADE;
DROP VIEW IF EXISTS fair CASCADE;
DROP VIEW IF EXISTS normal CASCADE;
DROP VIEW IF EXISTS high CASCADE;
DROP VIEW IF EXISTS high_low_combined CASCADE;
DROP VIEW IF EXISTS answerDepartedOnly CASCADE;
DROP VIEW IF EXISTS nondepartedflights CASCADE;
DROP VIEW IF EXISTS answerNotDepartedOnly CASCADE;


-- Define views for your intermediate steps here:

-- The relation below holds flight ids that have departed and their associated plane (tail_number) and airline.
CREATE VIEW DepartedFlights AS
SELECT distinct(Flight.id) as Flight_id, plane, airline
FROM Flight JOIN Departure ON Flight.id = Departure.flight_id
	        JOIN Booking on Booking.flight_id = Flight.id;

-- The relation below holds the passengers aboard a particular flight.
CREATE VIEW PassengersAboard AS
SELECT DepartedFlights.Flight_id, count (pass_id) as passengercount
From DepartedFlights join Booking on Booking.flight_id = DepartedFlights.Flight_id
GROUP BY DepartedFlights.Flight_id;

-- The relation below holds the plane's capacity on a given flight. 
CREATE VIEW PassengerCapacity AS 
SELECT distinct(DepartedFlights.Flight_id),capacity_economy + capacity_business + capacity_first as Capacity
FROM DepartedFlights join Plane on DepartedFLights.plane = Plane.tail_number
                     join Booking on Booking.flight_id = DepartedFlights.Flight_id;

-- The relation below holds the percentage capacity based on flight ids
CREATE VIEW combined AS
Select PassengersAboard.Flight_id, Capacity, passengercount, (passengercount/(capacity*1.000)) *100 AS Percentage
FROM PassengersAboard join PassengerCapacity on PassengersAboard.Flight_id = PassengerCapacity.Flight_id;

-- The relation below holds the count of the very low capacity percentage flights for a given <plane, airline> pair
CREATE VIEW very_low AS
SELECT Flight.plane as tail_number,airline, count (Flight.id) as very_low, 0 as low, 0 as fair, 0 as normal, 0 as high
FROM combined join Flight on combined.Flight_id = Flight.id
WHERE ((passengercount/((capacity*1.000)) *100) < 20)
GROUP BY FLight.plane, airline;

-- The relation below holds the count of the low capacity percentage flights for a given <plane, airline> pair
CREATE VIEW low AS
SELECT Flight.plane as tail_number,airline, 0 as very_low, count (Flight.id) as low, 0 as fair, 0 as normal, 0 as high
FROM combined join Flight on combined.Flight_id = Flight.id
WHERE ((passengercount/((capacity*1.000)) * 100) >= 20) and
      ((passengercount/((capacity*1.000)) * 100) < 40)
GROUP BY FLight.plane, airline;

-- The relation below holds the count of the fair capacity percentage flights for a given <plane, airline> pair
CREATE VIEW fair AS
SELECT Flight.plane as tail_number,airline, 0 as very_low, 0 as low, count (Flight.id) as fair, 0 as normal, 0 as high
FROM combined join Flight on combined.Flight_id = Flight.id
WHERE ((passengercount/((capacity*1.000)) *100) >= 40) and
      ((passengercount/((capacity*1.000)) *100) < 60)
GROUP BY FLight.plane, airline;

-- The relation below holds the count of the normal capacity percentage flights for a given <plane, airline> pair
CREATE VIEW normal AS
SELECT Flight.plane as tail_number,airline, 0 as very_low, 0 as low, 0 as fair, count (Flight.id) as normal, 0 as high
FROM combined join Flight on combined.Flight_id = Flight.id
WHERE ((passengercount/((capacity*1.000)) *100) >= 60) and
      ((passengercount/((capacity*1.000)) *100) < 80) 
GROUP BY FLight.plane, airline;

-- The relation below holds the count of the high capacity percentage flights for a given <plane, airline> pair
CREATE VIEW high AS
SELECT Flight.plane as tail_number,airline, 0 as very_low, 0 as low, 0 as fair, 0 as normal, count (Flight.id) as high     
FROM combined join Flight on combined.Flight_id = Flight.id
WHERE ((passengercount/((capacity*1.000)) *100) >= 80)
GROUP BY FLight.plane, airline;

-- Create a big relation that holds the count for reach percentage category. This table has multiple tuples for a given plane.
CREATE VIEW high_low_combined AS
(Select *
FROM very_low) union
(Select *
FROM low) union
(Select *
FROM fair) union
(Select *
FROM normal) union
(Select *
FROM high);

-- The following relation holds the count for each percentage category based on <tail_number, airline> pair only 
-- for the planes that actually departed.
CREATE VIEW answerDepartedOnly AS 
SELECT airline,tail_number, sum(very_low) as very_low, sum(low) as low, sum(fair) as fair, sum(normal) as normal, sum(high) as high
FROM high_low_combined
GROUP BY tail_number,airline;

-- The following relation holds the tail_number, airline of the planes that did not depart
CREATE VIEW nondepartedflights AS
(SELECT tail_number, airline FROM plane) except (SELECT plane, airline From DepartedFlights);

-- The following relation holds the airline, tail_number, and capacity info for the planes that did not depart
CREATE VIEW answerNotDepartedOnly AS
SELECT airline, tail_number, 0 as very_low, 0 as low, 0 as fair, 0 as normal, 0 as high
FROM nondepartedflights;

---------------------------------------------------------------------------
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4

-- The following query outputs the answer for this question of the assignments (holds the info for departed and not departed planes)
(SELECT * FROM answerDepartedOnly) union (SELECT * FROM answerNotDepartedOnly);
