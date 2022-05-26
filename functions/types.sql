create type dns_parent_a_record as (
  domain text,
  tld text,
  parent_server text,
  parent_ip inet
);

create type parent_server_ns_list as (
  domain text,
  parent_server text,
  target text
);

create type domain_parent_server_with_ip as (
  domain text,
  ip_text text
);

create type name_server_ip as (
  domain text,
  ip inet,
  type text,
  target text,
  ip_text text
);

create type control_output as (
  resource text,
  status text,
  reason text
);