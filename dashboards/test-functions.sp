locals {
  jonudell_info_name_server_count = 2
  whitehouse_gov_name_server_count = 1
}

dashboard "test_functions" {

    benchmark {
      title         = "Test name server functions"
      children = [
          control.test_name_server_subnets_jonudell_info,
          control.test_name_server_subnets_whitehouse_gov,
      ]
    }

  }

  control "test_name_server_subnets_jonudell_info" {
    title       = "Test the name_server_subnets function for jonudell.info"

    sql = <<-EOT
      select
        'test_name_server_subnets' as resource,
        case
            when count_of_name_server_subnets($1) != ${local.jonudell_info_name_server_count} then 'alarm'
            else 'ok'
        end as status,
        case
            when count_of_name_server_subnets($1) != ${local.jonudell_info_name_server_count} then 'Expected 2 for '
            else 'Found 2 for '
        end 
        || $1 as reason
      from
        net_dns_record
      where
        domain = $1
      group by 
        domain;
    EOT
    args = [
      "jonudell.info"
    ]
  }

    control "test_name_server_subnets_whitehouse_gov" {
    title       = "Test the name_server_subnets function for whitehouse.gov"

    sql = <<-EOT
      select
        'test_name_server_subnets' as resource,
        case
            when count_of_name_server_subnets($1) != ${local.whitehouse_gov_name_server_count} then 'alarm'
            else 'ok'
        end as status,
        case
            when count_of_name_server_subnets($1) != ${local.whitehouse_gov_name_server_count} then 'Expected 2 for '
            else 'Found 2 for'
        end 
        || $1 as reason
      from
        net_dns_record
      where
        domain = $1
      group by 
        domain;
    EOT
    args = [
      "whitehouse.gov"
    ]
  }

