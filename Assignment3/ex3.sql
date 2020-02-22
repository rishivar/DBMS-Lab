set linesize 200;
set echo on;

REM:1. Display the flight number,departure date and time of a flight, its route details and aircraft
REM:name of type either Schweizer or Piper that departs during 8.00 PM and 9.00 PM.

select fs.flno,fs.departs,fs.dtime,r.*,a.aname
from fl_schedule fs,flights f,routes r,aircraft a
where fs.flno=f.flightNo
and f.rID=r.routeID
and f.aid=a.aid
and (a.type='Schweizer' or a.type='Piper') and (fs.dtime>=2000 and fs.dtime<=2100);

REM:2. For all the routes, display the flight number, origin and destination airport, if a flight is
REM:assigned for that route.

select r.routeID,r.orig_airport,r.dest_airport,f.flightNo
from routes r,flights f where r.routeID=f.rID;

REM:3. For all aircraft with cruisingrange over 5,000 miles, find the name of the aircraft
REM:and the average salary of all pilots certified for this aircraft.

select a.aname,avg(e.salary)
from aircraft a,certified c,employee e
where c.aid=a.aid
and e.eid=c.eid
and a.cruisingrange>5000
group by a.aname;

REM:4. Show the employee details such as id, name and salary who are not pilots and whose salary
REM:is more than the average salary of pilots.

select e.* from employee e
left join certified c on c.eid=e.eid
where c.eid is null
and e.salary>(select avg(e1.salary) from employee e1 inner join certified c1
on c1.eid=e1.eid);

REM:5. Find the id and name of pilots who were certified to operate some aircrafts but at least one
REM:of that aircraft is not scheduled from any routes.

select e.eid,e.ename from employee e
inner join certified c on c.eid=e.eid
left join flights f on f.aid=c.aid
where f.rid is null
group by (e.eid,e.ename);

REM:6. Display the origin and destination of the flights having at least three departures with
REM:maximum distance covered.

select orig_airport, dest_airport
from routes
where (distance) in
(
	select max(distance)
	from
	(
		select rid, count(rid)
		from flights, fl_schedule
		where (flightno = flno)
		group by (rid)
		having count(rid) > 2
	), routes
where (routeid = rid)
);

REM:7. Display name and salary of pilot whose salary is more than the average salary of any pilots
REM:for each route other than flights originating from Madison airport.

select distinct e.ename,e.salary
from employee e,certified c
where c.eid=e.eid and e.salary > ANY
(
         select avg(e.salary)
         from employee e,certified c,flights f,routes r
         where e.eid=c.eid and c.aid=f.aid and f.rID=r.routeID
         and r.orig_airport!='Madison'
         group by r.routeID
);

REM:8. Display the flight number, aircraft type, source and destination airport of the aircraft
REM:having maximum number of flights to Honolulu.

select f.flightNo,a.type,r.orig_airport,r.dest_airport
from flights f,aircraft a,routes r
where f.rID=r.routeID and a.aid=f.aid
and r.dest_airport='Honolulu'
and a.aid=
(select a3.aid from flights f3,aircraft a3,routes r3
where f3.rID=r3.routeID and a3.aid=f3.aid and r3.dest_airport='Honolulu' group by a3.aid
having count(*)=
(select max(c) as m from (select count(*) as c from flights f1,aircraft a1,routes r1
where f1.rID=r1.routeID and a1.aid=f1.aid and r1.dest_airport='Honolulu' group by a1.aid)));

REM:9. Display the pilot(s) who are certified exclusively to pilot all aircraft in a type.
 
select distinct(c.eid), e.ename, a.type from certified c, aircraft a, employee e
 where c.eid in
 (
         select c1.eid
         from certified c1, aircraft a1
         where c1.aid=a1.aid
         having count(distinct a1.type)=1
         group by c1.eid
 ) and c.aid=a.aid and c.eid = e.eid
 group by c.eid,a.type, e.ename
 having count(*)=
 (
         select count(air.aid)
         from aircraft air
         where air.type=a.type
 );

REM:10. Name the employee(s) who is earning the maximum salary among the airport having
REM:maximum number of departures.

select e3.ename,e3.salary from employee e3 where e3.salary=
(select max(sal) from (select distinct e2.ename,e2.salary as sal
from employee e2,flights f2,routes r2,aircraft a2,certified c2
where r2.routeId=f2.rid and f2.aid=a2.aid and e2.eid=c2.eid and c2.aid=a2.aid and
r2.orig_airport=
(select r1.orig_airport from routes r1,flights f1
where r1.routeId=f1.rid group by r1.orig_airport having count(*)=
(select max(c) as m from (select count(*) as c from routes r,flights f
where r.routeid=f.rid group by r.orig_airport)))));

REM:11. Display the departure chart as follows:
REM:flight number, departure(date,airport,time), destination airport, arrival time, aircraft name
REM:for the flights from New York airport during 15 to 19th April 2005. Make sure that the route
REM:contains at least two flights in the above specified condition.

 select f.flightNo,fs.departs,r.orig_airport,fs.dtime,
 r.dest_airport,fs.arrives,fs.atime,a.type
 from fl_schedule fs,flights f,routes r,aircraft a
 where fs.flno=f.flightNo and f.rID=r.routeID and f.aid=a.aid
 and (r.orig_airport='New York') and
 (fs.departs between '15-apr-2005' and '19-apr-2005') and
 (
         select count(fs.flno)
         from fl_schedule fs,flights f
         where f.rID=r.routeID and f.flightNo=fs.flno
 )>=2;

REM:12. A customer wants to travel from Madison to New York with no more than two changes of
REM:flight. List the flight numbers from Madison if the customer wants to arrive in New York by
REM:6.50 p.m.

select distinct f.flightNo from flights f,routes r,fl_schedule fs where f.rid=r.routeID and fs.flno=f.flightNo
and r.orig_airport='Madison' and r.dest_airport='New York' and fs.atime<=1850
union
select distinct f1.flightNo from flights f1,routes r1,fl_schedule fs1,flights f11,routes r11
where f1.rid=r1.routeID and fs1.flno=f11.flightNo and f11.rid=r11.routeID
and r1.orig_airport='Madison' and r11.dest_airport='New York' and r1.dest_airport=r11.orig_airport and fs1.atime<=1850
union
select distinct f2.flightNo from flights f2,routes r2,fl_schedule fs2,flights f21,routes r21,flights f22,routes r22
where f2.rid=r2.routeID and fs2.flno=f22.flightNo and f21.rid=r21.routeID  and f22.rid=r22.routeID
and r2.orig_airport='Madison' and r22.dest_airport='New York' and r2.dest_airport=r21.orig_airport
and r21.dest_airport=r22.orig_airport and fs2.atime<=1850;

REM:13. Display the id and name of employee(s) who are not pilots.

select e1.eid,e1.ename from employee e1
where e1.eid in
(select e.eid from employee e
minus
select c.eid from certified c);

REM:14. Display the id and name of employee(s) who pilots the aircraft from Los Angeles and Detroit
REM:airport.

select distinct e.eid,e.ename from employee e,certified c,routes r,flights f,aircraft a
where e.eid=c.eid and r.routeID=f.rID and f.aid=a.aid and c.aid=a.aid
and r.orig_airport='Los Angeles'
intersect
select distinct e.eid,e.ename from employee e,certified c,routes r,flights f,aircraft a
where e.eid=c.eid and r.routeID=f.rID and f.aid=a.aid and c.aid=a.aid
and r.orig_airport='Detroit';
