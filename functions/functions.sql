create or replace function domain_records(_domain text) 
  returns setof net_dns_record as $$
  select * from net_dns_record where domain = _domain;
$$ language sql;

create or replace function domain_records_for_type(_domain text, _type text)
  returns setof net_dns_record as $$
  begin
    return query 
      select 
        *
      from 
        domain_records(_domain) 
      where 
        type = _type
      order by 
        domain;
  end;
$$ language plpgsql;

create or replace function tld_for_domain(domain text) returns text as $$
  select
    substring(
      domain
      from
        '^(?:[^/:]*:[^/@]*@)?(?:[^/:.]*\.)+([^:/]+)'
    );
$$ language sql;

create or replace function dns_record_count(_domain text) returns 
  table(domain text, count bigint) as $$
  select 
    domain, 
    count(*) 
  from 
    domain_records(_domain) 
  group by 
    domain
$$ language sql;

create or replace function dns_record_count_for_type(_domain text, _type text) 
  returns table(domain text, count bigint) as $$
  select 
    domain, 
    count(*) 
  from 
    domain_records_for_type(_domain, _type) 
  group by 
    domain
$$ language sql;

create or replace function domain_list(_domain text) returns 
  table (domain text, tld text) as $$
  select distinct
    domain,
    tld_for_domain(_domain) as tld
  from
    net_dns_record
  where
    domain = _domain;
$$ language sql;

create or replace function domain_parent_server(_domain text) 
  returns table (domain text, tld text, parent_server text) as $$
  with domain_list as (
    select * from domain_list(_domain)
  )
  select 
    l.domain, 
    d.domain as tld, 
    d.target as parent_server 
  from 
    net_dns_record d
  join 
    domain_list l 
  on 
    d.domain = l.tld 
  where 
    d.type = 'SOA';
$$ language sql;

create or replace function domain_parent_server_ip(_domain text) 
  returns setof net_dns_record as $$
  begin
    return query
      with domain_parent_server as (
        select * from domain_parent_server(_domain)
      )
      select 
        * 
      from 
        net_dns_record 
      where 
        domain in (select parent_server from domain_parent_server);
  end;
$$ language plpgsql;

create or replace function dns_parent_a_record(_domain text) 
  returns setof dns_parent_a_record as $$
  begin
    return query
      with domain_parent_server as (
        select * from domain_parent_server(_domain)
      ),
      domain_parent_server_ip as (
        select * from domain_parent_server_ip(_domain)
      )
      select 
        dps.domain,
        dps.tld,
        dps.parent_server,
        dps_ip.ip
      from 
        domain_parent_server dps
      join 
        domain_parent_server_ip dps_ip
      on
        dps.parent_server = dps_ip.domain
      where
        dps_ip.type = 'A'
      order by 
        dps.domain;
    end;
$$ language plpgsql;

create or replace function domain_parent_server_with_ip(_domain text) 
  returns setof domain_parent_server_with_ip as $$
  begin
    return query
      with domain_parent_server as (
        select * from domain_parent_server(_domain)
      ),
      domain_parent_server_ip as (
        select * from domain_parent_server_ip(_domain)
      )
      select 
        dps.domain, 
        host(dps_ip.ip) as ip_text
      from 
        domain_parent_server dps
      join 
        domain_parent_server_ip dps_ip 
      on 
        dps.parent_server = dps_ip.domain 
      where 
        dps_ip.type = 'A' order by dps.domain;
  end;  
$$ language plpgsql;

create or replace function domain_parent_server_ns_info(_domain text) returns table(domain text, target text) as $$
  with domain_parent_server_with_ip as (
    select * from domain_parent_server_with_ip(_domain)
  )
  select 
    ndr.domain, 
      ndr.target 
    from 
      net_dns_record ndr
    join 
      domain_parent_server_with_ip dps_ip
    on 
      ndr.domain = dps_ip.domain 
      and ndr.dns_server = dps_ip.ip_text 
      and ndr.type = 'NS'
    order by
      ndr.domain;
$$ language sql;

create or replace function domain_parent_server_ns_list(_domain text) returns setof parent_server_ns_list as $$
  begin
    return query
       with dns_parent_a_record as (
        select * from dns_parent_a_record(_domain)
      ),
      domain_parent_server_ns_list as (
        select 
          ndr.domain, 
          dpr.parent_server, 
          ndr.target 
        from 
          net_dns_record ndr
        join 
          dns_parent_a_record dpr
        on 
          ndr.domain = dpr.domain 
          and ndr.dns_server = host(dpr.parent_ip) 
          and ndr.type = 'NS' 
        order 
          by ndr.domain
      )
      select * from domain_parent_server_ns_list;
  end;
$$ language plpgsql;

create or replace function test_domain_parent_server_ns_list(_domain text, _expected text) 
  returns control_output as $$
    select
      '' as resource,
      case
          when (
            select _expected in (select parent_server from domain_parent_server_ns_list(_domain))
          ) then 'ok'
          else 'alarm'
      end as status,
      '' as reason
$$ language sql;

create or replace function domain_name_server_ips(_domain text) returns setof name_server_ip as $$
  begin
    return query
      with
        domain_ns_records as (
          select * from domain_records_for_type(_domain, 'NS')
        )
      select 
        domain, 
        ip,
        type,
        target,
        host(ip) as ip_text 
      from 
        net_dns_record 
      where 
        domain in (select target from domain_ns_records) and type = 'A';
  end;
$$ language plpgsql;

create or replace function test_domain_name_server_ips(_domain text, _expected text) 
  returns control_output as $$
    select
      '' as resource,
      case
          when (
            select _expected in (select domain from domain_name_server_ips(_domain))
          ) then 'ok'
          else 'alarm'
      end as status,
      '' as reason
$$ language sql;

create or replace function ip_is_private(_ip inet) returns boolean as $$
  select (
    _ip << '10.0.0.0/8'::inet or 
    _ip << '100.64.0.0/10'::inet or 
    _ip << '172.16.0.0/12'::inet or 
    _ip << '192.0.0.0/24'::inet or 
    _ip << '192.168.0.0/16'::inet or 
    _ip << '198.18.0.0/15'::inet
  );
$$ language sql;

create or replace function valid_nameserver_target() returns text as $$
  select '^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}\.?$';
$$ language sql;

create or replace function subnet_for_ip(_ip text) returns text as $$
  select regexp_replace(_ip, '\.\d+$', '');
$$ language sql;

create or replace function name_server_subnets(_domain text) returns table (name_server_ip text, subnet text) as $$
  with domain_ns_records as (
    select * from domain_records_for_type(_domain, 'NS')
  ),
  domain_name_server_ips as (
    select * from domain_name_server_ips(_domain)
  )
  select distinct 
    ns_ips.ip_text,
    subnet_for_ip(ns_ips.ip_text)
  from
    domain_ns_records dnr
  join 
    domain_name_server_ips ns_ips 
  on 
    dnr.target = ns_ips.domain
  where
    ns_ips.type = 'A' and dnr.type = 'NS'
$$ language sql;

create or replace function count_of_name_server_subnets(_domain text) returns bigint as $$
  select count(*) from name_server_subnets(_domain)
$$ language sql;

create or replace function test_name_server_subnets(_domain text, _expected int) 
  returns control_output as $$
    select
      '' as resource,
      case
          when count_of_name_server_subnets(_domain) != _expected then 'alarm'
          else 'ok'
      end as status,
      '' as reason
$$ language sql;