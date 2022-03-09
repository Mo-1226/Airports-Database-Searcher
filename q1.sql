-- Q1. Airlines

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    pass_id INT,
    name VARCHAR(100),
    airlines INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS TookOffFlightsPassengers CASCADE;
DROP VIEW IF EXISTS NotTookOffFlightsPassengers CASCADE;
DROP VIEW IF EXISTS Q1ANSWER CASCADE;


-- Define views for your intermediate steps here:

-- This relation holds the data of the passengers who's flights haven taken off
CREATE VIEW TookOffFlightsPassengers AS
SELECT Passenger.id as passenger, firstname||' '||surname as name, count(distinct airline) as airlines
FROM Departure JOIN Flight on Departure.flight_id = Flight.id
               JOIN Booking on Flight.id = Booking.flight_id
               JOIN Passenger on Passenger.id = Booking.pass_id
GROUP BY Passenger.id;

-- This relation holds the passenger ids of the passengers who's flights haven't taken off
CREATE VIEW NotTookOffFlightsPassengers AS 
(SELECT Passenger.id
FROM Passenger) except (SELECT passenger FROM TookOffFlightsPassengers);

-- This relation holds the passenger id, their name, and the number of different airlines they took flight in including every passenger even if they have never taken a flight
CREATE VIEW Q1ANSWER AS
(SELECT Passenger.id as pass_id, firstname ||' '||surname as name, 0 as airlines
FROM NotTookOffFlightsPassengers JOIN Passenger on NotTookOffFlightsPassengers.id = Passenger.id) union (SELECT * FROM TookOffFlightsPassengers);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1

--Print out the answer of q1 and order by pass_id
SELECT *
FROM Q1ANSWER
ORDER BY pass_id;



