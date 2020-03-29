

--Original code from MercyCare
IF OBJECT_ID('tempdb..#OriginalTriad') IS NOT NULL DROP TABLE #OriginalTriad
SELECT DISTINCT
	p1.provid
	, p1.fullname
	, p3.provid AS locationid
	, locationname = RTRIM(p3.fullname)
into #OriginalTriad
FROM planreport_QNXT_TXMS.dbo.provider				p1 (nolock)
JOIN planreport_QNXT_TXMS.dbo.affiliation			a  (nolock) ON p1.provid = a.provid 
			AND GETDATE() BETWEEN a.effdate AND a.termdate
JOIN planreport_QNXT_TXMS.dbo.provider				p2 (nolock) ON a.affiliateid = p2.provid
JOIN planreport_QNXT_TXMS.dbo.contractinfo			i  (nolock) ON a.affiliationid = i.affiliationid 
			AND GETDATE() BETWEEN i.effdate AND i.termdate
LEFT JOIN planreport_QNXT_TXMS.dbo.provspecialty	ps (nolock) ON p1.provid = ps.provid 
			AND GETDATE() BETWEEN ps.effdate AND ps.termdate 
			AND ps.spectype = 'PRIMARY'
LEFT JOIN planreport_QNXT_TXMS.dbo.specialty		s  (nolock) ON ps.specialtycode = s.specialtycode
JOIN planreport_QNXT_TXMS.dbo.affiliation			a2 (nolock) ON p1.provid = a2.provid 
			AND a2.affiltype = 'SERVICE' 
			AND GETDATE() BETWEEN a2.effdate AND a2.termdate
JOIN planreport_QNXT_TXMS.dbo.provider				p3 (nolock) ON a2.affiliateid = p3.provid 
			AND p3.servlocation <> 0 
			AND p3.status = 'ACTIVE'
WHERE p1.provid <> ''
	and p3.provid NOT IN(SELECT x.affiliateid FROM planreport_QNXT_TXMS.dbo.affiliation x (nolock)
						WHERE x.provid = p2.provid 
						AND GETDATE() BETWEEN x.effdate AND x.termdate
						AND x.affiltype IN('SERVICE','SITE'))


--Updated code from Philbo
IF OBJECT_ID('tempdb..#preTriad') IS NOT NULL DROP TABLE #preTriad
select distinct   
	p1.Provid
	, ProvName = p1.Fullname
	, p1.ProvType
	, Groupid = p2.provid
	, GroupNPI = p2.NPI
	, GroupTIN = p2.fedid
	, Locationid = p3.provid	
	, LocationName = rtrim(p3.fullname)
into #preTriad
from planreport_QNXT_TXMS.dbo.provider p1 (nolock)
	-----------------------------------------------------------------------
	--payto or group
	inner join planreport_QNXT_TXMS.dbo.affiliation a  (nolock) 
		ON p1.provid = a.provid	
		AND getdate() between a.effdate and a.termdate
	inner join planreport_QNXT_TXMS.dbo.provider p2 (nolock) 
		ON a.affiliateid = p2.provid
	inner join planreport_QNXT_TXMS.dbo.contractinfo	i  (nolock) 
		ON a.affiliationid = i.affiliationid 
		and getdate() between i.effdate and i.termdate
	-----------------------------------------------------------------------
	--Location --looked in config handbook and location doesn't need contractinfo join
	inner join planreport_QNXT_TXMS.dbo.affiliation a2 (nolock) 
		ON p1.provid = a2.provid
		and a2.affiltype = 'service' --physical service location
		and getdate() between a2.effdate and a2.termdate   	     
	inner join planreport_QNXT_TXMS.dbo.provider p3 (nolock) 
		ON a2.affiliateid = p3.provid
		and p3.servlocation <> 0
		and p3.status = 'active'
where p1.provid <> ''


IF OBJECT_ID('tempdb..#Triad') IS NOT NULL DROP TABLE #Triad
select 
	pt.Provid
	, pt.ProvName
	, pt.Locationid
	, pt.LocationName
	, IsTriad = count(distinct x.affiliateid) --has trifecta affiliation
	, MaxGroupid = max(x.provid) --this is used to find at least one common group between location and provider 
into #Triad
from #preTriad pt
	left join --by provid
		(	select distinct  provid, affiliateid  
			from planreport_QNXT_TXMS.dbo.affiliation x (nolock) -- active service and site locations with active affiliations
			where affiltype in ('site','service')			
				and provid <> ''		
				AND GETDATE() BETWEEN x.effdate AND x.termdate
		) x
		on x.provid = pt.groupid 
		and x.affiliateid = pt.locationid
group by
	pt.Provid
	, ProvName
	, locationid
	, locationname


--Location ids in original code that probably shouldn't be there
select distinct locationid  from #triad where locationid not in (select locationid from #OriginalTriad)


select * from #Triad where locationid = 'QXIPQ0000167593'


--Check against original code
select 
	t.*
	, IsTriadOriginal = case when ft.provid is null then 1 else 0 end 
	, MethodologyDiscrepancy = case when case when ft.provid is null then 1 else 0 end <> IsTriad then 1 else 0 end --Where new code and original code give different result
	, ft.* 
from #Triad t 
	left join #OriginalTriad ft 
		on t.locationid = ft.locationid
		and t.provid = ft.provid 
--where t.locationid = 'QXIPQ0000092589'
order by t.Locationid


select * from #Triad where locationid = 'PDZ000000027977'

select * from #OriginalTriad where locationid = 'PDZ000000027977'



--Validation Checks
declare @provid varchar(max) = 'PROV0000A44940 '
declare @locationid varchar(max) = 'PDZ000000027977'
declare @groupid varchar(max) = 'QZZ000000127960'

select provid = @provid, locationid = @locationid, groupid = @groupid

select Relationship = 'Prov to Group', a.provid, ProvName = p.fullname, a.affiliateid, AffilName = p2.fullname, a.effdate, a.termdate, a.affiltype, a.status
from planreport_QNXT_TXMS.dbo.affiliation a
	left join planreport_QNXT_TXMS.dbo.provider p on p.provid = a.provid 
	left join planreport_QNXT_TXMS.dbo.provider p2 on p2.provid = a.affiliateid 
where a.provid = @provid --provider
	and a.affiliateid = @groupid --group

union

select 'Prov to Location', a.provid, ProvName = p.fullname, a.affiliateid, AffilName = p2.fullname, a.effdate, a.termdate, a.affiltype, a.status
from planreport_QNXT_TXMS.dbo.affiliation a
	left join planreport_QNXT_TXMS.dbo.provider p on p.provid = a.provid 
	left join planreport_QNXT_TXMS.dbo.provider p2 on p2.provid = a.affiliateid 
where a.provid = @provid --provider
	and a.affiliateid = @locationid --location

union 

select 'Group to Location', a.provid, ProvName = p.fullname, a.affiliateid, AffilName = p2.fullname, a.effdate, a.termdate, a.affiltype, a.status
from planreport_QNXT_TXMS.dbo.affiliation a
	left join planreport_QNXT_TXMS.dbo.provider p on p.provid = a.provid 
	left join planreport_QNXT_TXMS.dbo.provider p2 on p2.provid = a.affiliateid 
where a.provid = @groupid --group 
	and affiliateid = @locationid --location
order by Relationship desc 





--Validation Checks
declare @provid varchar(max) = 'PDZ000000060824'
declare @locationid varchar(max) = 'PDZ000000057136'
declare @groupid varchar(max) = 'PROV0000A42217 '


select 'Group to Location', a.provid, ProvName = p.fullname, a.affiliateid, AffilName = p2.fullname, a.effdate, a.termdate, a.affiltype, a.status, p.fedid, *
from planreport_QNXT_TXMS.dbo.affiliation a
	left join planreport_QNXT_TXMS.dbo.provider p on p.provid = a.provid 
	left join planreport_QNXT_TXMS.dbo.provider p2 on p2.provid = a.affiliateid 
where a.provid = @groupid --group 
	and affiliateid = @locationid --location



select




select distinct 
	p1.provid
	, p1.ProvName
	--, Groupid = p2.provid 
	--, GroupName = p2.fullname
from #triad p1
	inner join planreport_QNXT_TXMS.dbo.affiliation a  (nolock) 
		ON p1.provid = a.provid	
		AND getdate() between a.effdate and a.termdate
	inner join planreport_QNXT_TXMS.dbo.provider p2 (nolock) 
		ON a.affiliateid = p2.provid
	inner join planreport_QNXT_TXMS.dbo.contractinfo	i  (nolock) 
		ON a.affiliationid = i.affiliationid 
		and getdate() between i.effdate and i.termdate
where p1.IsTriadAll = 0 



