dashboard "test_functions" {

  title = "Net Insights self-test"

  tags = {
    service  = "Net/DNS"
    type     = "Self Test"
  }

  benchmark {
      title         = "Test name server functions"
      children = [
          control.name_server_subnets_jonudell_info,
          control.name_server_subnets_whitehouse_gov,
          control.name_server_ips_for_jonudell_info_include_expected,
          control.domain_parent_server_ns_list_for_jonudell_info,
          control.dns_parent_a_record_for_jonudell_info
      ]
    }

  }

  control "name_server_subnets_jonudell_info" {
    sql = <<EOT
      select * from test_name_server_subnets('jonudell.info', 2)
    EOT
  }

  control "name_server_subnets_whitehouse_gov" {
    sql = <<EOT
      select * from test_name_server_subnets('whitehouse.gov', 6)
    EOT
  }

  control "name_server_ips_for_jonudell_info_include_expected" {
    sql = <<EOT
      select * from test_domain_name_server_ips('jonudell.info', 'ns1.bluehost.com.')
    EOT
  }

  control "domain_parent_server_ns_list_for_jonudell_info" {
    sql = <<EOT
      select * from test_domain_parent_server_ns_list('jonudell.info', 'a0.info.afilias-nst.info.')
    EOT
  }

    control "dns_parent_a_record_for_jonudell_info" {
    sql = <<EOT
      select * from test_dns_parent_a_record('jonudell.info', 'a0.info.afilias-nst.info.')
    EOT
  }





