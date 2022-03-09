-- Q3. North and South Connections

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    outbound VARCHAR(30),
    inbound VARCHAR(30),
    direct INT,
    one_con INT,
    two_con INT,
    earliest timestamp
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS outbound CASCADE;
DROP VIEW IF EXISTS inbound CASCADE; 
DROP VIEW IF EXISTS RelevantFlights CASCADE;
DROP VIEW IF EXISTS oneConnection CASCADE;
DROP VIEW IF EXISTS TwoConnections CASCADE;
DROP VIEW IF EXISTS directFlight CASCADE;
DROP VIEW IF EXISTS FinalAnswer CASCADE;


-- Define views for your intermediate steps here:

-- Table that holds flights departing from a Canadian airport or American airport
CREATE VIEW outbound AS 
SELECT id, code, outbound,city, country, s_dep, s_arv
FROM airport join flight on airport.code = flight.outbound
WHERE (airport.country = 'Canada' or airport.country = 'USA');

-- Table that holds flights arriving to a Canadian airport or American airport
CREATE VIEW inbound AS 
SELECT id, code, inbound,city, country, s_dep, s_arv
FROM airport join flight on airport.code = flight.inbound
WHERE (airport.country = 'Canada' or airport.country = 'USA');

-- Table that holds outbound to inbound flight data within Canada and America 
CREATE VIEW RelevantFlights AS
SELECT inbound.id, outbound.code as outbound, outbound.city as outboundcity, outbound.country as outboundcountry, inbound.code as inbound,inbound.city as inboundcity, inbound.country as inboundcountry, inbound.s_dep, inbound.s_arv 
FROM inbound join outbound on inbound.id = outbound.id;

-- Table that holds the different # of routes between <outbound, inbound> city pair that require one connection and the min arrival times for each pair
CREATE VIEW oneConnection AS
SELECT RF1.outboundcity as outbound, RF2.inboundcity as inbound, 0 as direct, count(*) as one_con, 0 as two_con, min(RF2.s_arv)
FROM RelevantFlights RF1 join RelevantFlights RF2 on RF1.inboundcity = RF2.outboundcity
WHERE RF1.outboundCountry != RF2.inboundCountry and (RF1.s_arv + interval '30 min')  <= RF2.s_dep
      and RF1.s_dep >= timestamp'2021-04-30 00:00' and RF1.s_dep < timestamp'2021-05-01 00:00'
      and RF2.s_dep > timestamp'2021-04-30 00:00' and RF2.s_dep < timestamp'2021-05-01 00:00'
      and RF1.s_arv > timestamp'2021-04-30 00:00' and RF1.s_arv < timestamp'2021-05-01 00:00'
      and RF2.s_arv > timestamp'2021-04-30 00:00' and RF2.s_arv < timestamp'2021-05-01 00:00'
GROUP BY RF1.outboundcity, RF2.inboundcity;

-- Table that holds the different # of routes between <outbound, inbound> city pair that require two connections and the min arrival times for each pair
CREATE VIEW TwoConnections AS
SELECT RF1.outboundcity as outbound, RF3.inboundcity as inbound, 0 as direct, 0 as one_con, count(*) as two_con, min(RF3.s_arv)
FROM RelevantFlights RF1 join RelevantFlights RF2 on RF1.inboundcity = RF2.outboundcity
                         join RelevantFlights RF3 on RF2.inboundcity = RF3.outboundcity
WHERE RF1.outboundCountry != RF3.inboundCountry and (RF1.s_arv + interval '30 min')  <= RF2.s_dep
    and RF1.s_dep >= timestamp'2021-04-30 00:00' and RF1.s_dep < timestamp'2021-05-01 00:00'
    and RF1.s_arv > timestamp'2021-04-30 00:00'and RF1.s_arv < timestamp'2021-05-01 00:00' 
    and RF2.s_dep > timestamp'2021-04-30 00:00' and RF2.s_dep < timestamp'2021-05-01 00:00'
    and (RF2.s_arv + interval '30 min')  <= RF3.s_dep
    and RF2.s_arv > timestamp'2021-04-30 00:00'and RF2.s_arv < timestamp'2021-05-01 00:00' 
    and RF3.s_dep > timestamp'2021-04-30 00:00' and RF3.s_dep < timestamp'2021-05-01 00:00'
    and RF3.s_arv > timestamp'2021-04-30 00:00'and RF3.s_arv < timestamp'2021-05-01 00:00'
GROUP BY RF1.outboundcity, RF3.inboundcity;

-- Table that holds the different # of routes between <outbound, inbound> city pair that require 0 connections (direct flights) and the min arrival times for each pair
CREATE VIEW directFlight AS
SELECT outbound.city as outbound, inbound.city as inbound, count(*) as direct,0 as one_con,0 as two_con, min(inbound.s_arv)
FROM inbound join outbound on inbound.id = outbound.id and inbound.country!= outbound.country and 
                              (inbound.country = 'Canada' or inbound.country = 'USA') and
                                                           (outbound.country = 'Canada' or outbound.country = 'USA')
WHERE inbound.s_dep >= timestamp'2021-04-30 00:00' and inbound.s_dep < timestamp'2021-05-01 00:00'
and inbound.s_arv < timestamp'2021-05-01 00:00'
GROUP BY inbound.city, outbound.city;

-- Table that combines the direct flight, one connection, two connection information
CREATE VIEW FinalAnswer AS
(SELECT * FROM oneConnection) union (SELECT * FROM directFlight) union (SELECT * FROM TwoConnections);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3

-- Table that is the final answer 
Select outbound, inbound, sum(direct) as direct, sum(one_con) as one_con, sum(two_con) as two_con, min(min) as earliest
FROM FinalAnswer
GROUP BY outbound, inbound;


