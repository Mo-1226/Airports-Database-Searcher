-- Q2. Refunds!

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS outbound CASCADE;
DROP VIEW IF EXISTS inbound CASCADE;
DROP VIEW IF EXISTS domestic CASCADE;
DROP VIEW IF EXISTS international CASCADE;
DROP VIEW IF EXISTS departedDomestic CASCADE;
DROP VIEW IF EXISTS domesticDelays CASCADE;
DROP VIEW IF EXISTS domesticdelaysArrivalDeparture10 CASCADE;
DROP VIEW IF EXISTS norefund10 CASCADE;
DROP VIEW IF EXISTS hourrefund10 CASCADE;
DROP VIEW IF EXISTS domesticdelaysArrivalDeparture5 CASCADE;
DROP VIEW IF EXISTS norefund5 CASCADE;
DROP VIEW IF EXISTS hourrefund5 CASCADE;
DROP VIEW IF EXISTS economyrefund10 CASCADE;
DROP VIEW IF EXISTS economyrefund5 CASCADE;
DROP VIEW IF EXISTS businessrefund10 CASCADE;
DROP VIEW IF EXISTS businessrefund5 CASCADE;
DROP VIEW IF EXISTS firstrefund10 CASCADE;
DROP VIEW IF EXISTS firstrefund5 CASCADE;
DROP VIEW IF EXISTS finalDomestic CASCADE;
DROP VIEW IF EXISTS departedInternational CASCADE;
DROP VIEW IF EXISTS internationalDelays CASCADE;
DROP VIEW IF EXISTS internationaldelaysArrivalDeparture12 CASCADE;
DROP VIEW IF EXISTS norefund12 CASCADE;
DROP VIEW IF EXISTS hourrefund12 CASCADE;
DROP VIEW IF EXISTS internationaldelaysArrivalDeparture8 CASCADE;
DROP VIEW IF EXISTS norefund8 CASCADE;
DROP VIEW IF EXISTS hourrefund8 CASCADE;
DROP VIEW IF EXISTS economyrefund12 CASCADE;
DROP VIEW IF EXISTS economyrefund8 CASCADE;
DROP VIEW IF EXISTS businessrefund12 CASCADE;
DROP VIEW IF EXISTS businessrefund8 CASCADE;
DROP VIEW IF EXISTS firstrefund12 CASCADE;
DROP VIEW IF EXISTS firstrefund8 CASCADE;
DROP VIEW IF EXISTS finalInternational CASCADE;
DROP VIEW IF EXISTS CombineIntDom CASCADE;
DROP VIEW IF EXISTS FinalAnswerWithoutAirline CASCADE;

-- Define views for your intermediate steps here:

-- The following relation matches a country with an outbound airport code of a flight
CREATE VIEW outbound AS 
SELECT id, code, outbound, country
FROM airport join flight on airport.code = flight.outbound;

-- The following relation matches a country with the inbound airport code of a flight
CREATE VIEW inbound AS 
SELECT id, code, inbound, country
FROM airport join flight on airport.code = flight.inbound;

-- The following relation finds which flight ids are a domestic flight
CREATE VIEW domestic AS
SELECT inbound.id, outbound, inbound, inbound.country
FROM inbound join outbound on inbound.id = outbound.id and inbound.country = outbound.country;

-- The following relation finds which flight ids are international flights
CREATE VIEW international AS
SELECT inbound.id, outbound, inbound, inbound.country
FROM inbound join outbound on inbound.id = outbound.id and inbound.country != outbound.country;

-- The following relational finds the domestic flights that actually departed along with their departure and arrival times both scheduled and actual
CREATE VIEW departedDomestic AS
SELECT flight.id, flight.inbound, flight.outbound, country, airline, plane, s_dep, s_arv, departure.datetime as departureTime, Arrival.datetime as arrivalTime
FROM domestic join Flight on domestic.id = flight.id 
              join Departure on domestic.id = departure.flight_id
              join Arrival on domestic.id = arrival.flight_id;

-- The following relation finds the domestic flights that had delays
CREATE VIEW domesticDelays AS 
Select *
From departedDomestic 
WHERE s_dep != departureTime;

-- The following relation finds the domestic flights and their delay information for a departure delay greater than 10 hours (Departure) 
CREATE VIEW domesticdelaysArrivalDeparture10 AS
SELECT airline, id, s_dep, departureTime, (departureTime - s_dep) as departureDelay, s_arv, arrivalTime, (arrivalTime - s_arv) as arrivalDelay
FROM domesticDelays
WHERE (departureTime >= s_dep + interval '10 hours');

-- The following relation gives you the domestic flights that have a delay more than 10 hours but dont get a refund
CREATE VIEW norefund10 AS
SELECT airline, id,s_dep, departureTime, (departureTime - s_dep) as departureDelay, s_arv, arrivalTime, (arrivalTime - s_arv) as arrivalDelay
FROM domesticdelaysArrivalDeparture10
WHERE (arrivalDelay <= departureDelay/2);

-- The following relation gives you info on domestic flights that require a refund with departure delay greater than 10 hours
CREATE VIEW hourrefund10 AS
(SELECT *
FROM domesticdelaysArrivalDeparture10) except
(SELECT *
FROM norefund10);

-- The following relation gives you all domestic flights and their information for a departure delay greater than 5 hours and less than 10 hours  
CREATE VIEW domesticdelaysArrivalDeparture5 AS
SELECT airline, id,s_dep, departureTime, (departureTime - s_dep) as departureDelay, s_arv, arrivalTime, (arrivalTime - s_arv) as arrivalDelay
FROM domesticDelays
WHERE (departureTime >= s_dep + interval '5 hours' and departureTime <= s_dep + interval '10 hours');

-- The following relation gives you the domestic flights that have a departure delay more than 5 hours and less than 10 but dont get a refund
CREATE VIEW norefund5 AS
SELECT airline, id,s_dep, departureTime, (departureTime - s_dep) as departureDelay, s_arv, arrivalTime, (arrivalTime - s_arv) as arrivalDelay
FROM domesticdelaysArrivalDeparture5
WHERE (arrivalDelay <= departureDelay/2);

-- The folliwing relation gives you the info for flights that require a refund with departure delay greater than 5 hours less than 10
CREATE VIEW hourrefund5 AS
(SELECT *
FROM domesticdelaysArrivalDeparture5) except
(SELECT *
FROM norefund5);

-- table gives refund of 50% to economy for domestic flights
CREATE VIEW economyrefund10 AS
SELECT airline, EXTRACT(YEAR FROM s_dep) as year, 'economy'::seat_class as seat_class, sum(price)*0.5 as refund
FROM  hourrefund10 join Booking on hourrefund10.id = booking.flight_id
WHERE seat_class = 'economy'
GROUP BY airline, year;

-- 
CREATE VIEW economyrefund5 AS
SELECT airline, EXTRACT(YEAR FROM s_dep) as year, 'economy'::seat_class as seat_class, sum(price)*0.35 as refund
FROM  hourrefund5 join Booking on hourrefund5.id = booking.flight_id
WHERE seat_class = 'economy'
GROUP BY airline, year;

CREATE VIEW businessrefund10 AS
SELECT airline, EXTRACT(YEAR FROM s_dep) as year, 'business'::seat_class as seat_class, sum(price)*0.5 as refund
FROM  hourrefund10 join Booking on hourrefund10.id = booking.flight_id
WHERE seat_class = 'business'
GROUP BY airline, year;

CREATE VIEW businessrefund5 AS
SELECT airline, EXTRACT(YEAR FROM s_dep) as year, 'business'::seat_class as seat_class, sum(price)*0.35 as refund
FROM  hourrefund5 join Booking on hourrefund5.id = booking.flight_id
WHERE seat_class = 'business'
GROUP BY airline, year;

CREATE VIEW firstrefund10 AS
SELECT airline, EXTRACT(YEAR FROM s_dep) as year, 'first'::seat_class as seat_class, sum(price)*0.5 as refund
FROM  hourrefund10 join Booking on hourrefund10.id = booking.flight_id
WHERE seat_class = 'first'
GROUP BY airline, year;

CREATE VIEW firstrefund5 AS
SELECT airline, EXTRACT(YEAR FROM s_dep) as year, 'first'::seat_class as seat_class, sum(price)*0.35 as refund
FROM  hourrefund5 join Booking on hourrefund5.id = booking.flight_id
WHERE seat_class = 'first'
GROUP BY airline, year;

-- you might get multiple rows in this one for each airline (IMPORTANT, i think it might be fine)
CREATE VIEW finalDomestic AS
(SELECT *
FROM economyrefund10) union 
(SELECT * 
FROM businessrefund10) union
(SELECT * 
FROM firstrefund10) union 
(SELECT *
FROM economyrefund5) union
(SELECT *
FROM businessrefund5) union
(SELECT *
FROM firstrefund5);

---------------------------international-------------------------------------
-- Find the international flights that actually departed along with their departure and arrival times both scheduled and actual
CREATE VIEW departedInternational AS
SELECT flight.id, flight.inbound, flight.outbound, country, airline, plane, s_dep, s_arv, departure.datetime as departureTime, Arrival.datetime as arrivalTime
FROM international join Flight on international.id = flight.id 
              join Departure on international.id = departure.flight_id
              join Arrival on international.id = arrival.flight_id;

-- Find the international flights that had delays
CREATE VIEW internationalDelays AS 
Select *
From departedInternational
WHERE s_dep != departureTime;

--- gives u all international delay information greater than 12 hours (Departure) 
CREATE VIEW internationaldelaysArrivalDeparture12 AS
SELECT airline, id,s_dep, departureTime, (departureTime - s_dep) as departureDelay, s_arv, arrivalTime, (arrivalTime - s_arv) as arrivalDelay
FROM internationalDelays
WHERE (departureTime >= s_dep + interval '12 hours');

-- gives u the international flight airlines that have a delay more than 12 hours but dont get a refund
CREATE VIEW norefund12 AS
SELECT airline, id,s_dep, departureTime, (departureTime - s_dep) as departureDelay, s_arv, arrivalTime, (arrivalTime - s_arv) as arrivalDelay
FROM internationaldelaysArrivalDeparture12
WHERE (arrivalDelay <= departureDelay/2);

-- gives u the info for flights that require a refund with departure delay greater than 12 hours
CREATE VIEW hourrefund12 AS
(SELECT *
FROM internationaldelaysArrivalDeparture12) except
(SELECT *
FROM norefund12);

--- gives u all international delay information greater than 8 hours and less than 12 hours (Departure) 
CREATE VIEW internationaldelaysArrivalDeparture8 AS
SELECT airline, id,s_dep, departureTime, (departureTime - s_dep) as departureDelay, s_arv, arrivalTime, (arrivalTime - s_arv) as arrivalDelay
FROM internationalDelays
WHERE (departureTime >= s_dep + interval '8 hours' and departureTime <= s_dep + interval '12 hours');

--- gives u the airlines (international flights) that have a delay more than 8 hours and less than 12 but dont get a refund
CREATE VIEW norefund8 AS
SELECT airline, id,s_dep, departureTime, (departureTime - s_dep) as departureDelay, s_arv, arrivalTime, (arrivalTime - s_arv) as arrivalDelay
FROM internationaldelaysArrivalDeparture8
WHERE (arrivalDelay <= departureDelay/2);

-- gives u the info for flights that require a refund with departure delay greater than 8 hours less than 12
CREATE VIEW hourrefund8 AS
(SELECT *
FROM internationaldelaysArrivalDeparture8) except
(SELECT *
FROM norefund8);


CREATE VIEW economyrefund12 AS
SELECT airline, EXTRACT(YEAR FROM s_dep) as year, 'economy'::seat_class as seat_class, sum(price)*0.5 as refund
FROM  hourrefund12 join Booking on hourrefund12.id = booking.flight_id
WHERE seat_class = 'economy'
GROUP BY airline, year;

CREATE VIEW economyrefund8 AS
SELECT airline, EXTRACT(YEAR FROM s_dep) as year, 'economy'::seat_class as seat_class, sum(price)*0.35 as refund
FROM  hourrefund8 join Booking on hourrefund8.id = booking.flight_id
WHERE seat_class = 'economy'
GROUP BY airline, year;

CREATE VIEW businessrefund12 AS
SELECT airline, EXTRACT(YEAR FROM s_dep) as year, 'business'::seat_class as seat_class, sum(price)*0.5 as refund
FROM  hourrefund12 join Booking on hourrefund12.id = booking.flight_id
WHERE seat_class = 'business'
GROUP BY airline, year;

CREATE VIEW businessrefund8 AS
SELECT airline, EXTRACT(YEAR FROM s_dep) as year, 'business'::seat_class as seat_class, sum(price)*0.35 as refund
FROM  hourrefund8 join Booking on hourrefund8.id = booking.flight_id
WHERE seat_class = 'business'
GROUP BY airline, year;

CREATE VIEW firstrefund12 AS
SELECT airline, EXTRACT(YEAR FROM s_dep) as year, 'first'::seat_class as seat_class, sum(price)*0.5 as refund
FROM  hourrefund12 join Booking on hourrefund12.id = booking.flight_id
WHERE seat_class = 'first'
GROUP BY airline, year;

CREATE VIEW firstrefund8 AS
SELECT airline, EXTRACT(YEAR FROM s_dep) as year, 'first'::seat_class as seat_class, sum(price)*0.35 as refund
FROM  hourrefund8 join Booking on hourrefund8.id = booking.flight_id
WHERE seat_class = 'first'
GROUP BY airline, year;

CREATE VIEW finalInternational AS 
(SELECT *
FROM economyrefund12) union 
(SELECT * 
FROM businessrefund12) union
(SELECT * 
FROM firstrefund12) union 
(SELECT *
FROM economyrefund8) union
(SELECT *
FROM businessrefund8) union
(SELECT *
FROM firstrefund8);

CREATE VIEW CombineIntDom AS
(SELECT *
FROM finalInternational ) union (SELECT * FROM finalDomestic);

CREATE VIEW FinalAnswerWithoutAirline AS
SELECT airline, year, seat_class, sum(refund) as refund
FROM CombineIntDom
GROUP BY airline, year, seat_class;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2

SELECT airline, name, year, seat_class, refund
FROM FinalAnswerWithoutAirline join Airline on Airline.code = FinalAnswerWithoutAirline.airline;

