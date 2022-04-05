dashboard "website_header_check" {

  title = "Website Headers Detail"

  input "site_url" {
    title = "Select a address:"
    width = 4
    option "https://turbot.com" { label = "turbot.com" }
    option "https://steampipe.io" { label = "steampipe.io" }
  }

  container {
    width = 12

    card {
      width = 2

      query = query.strict_transport_security_check
      args = {
        site_url = self.input.site_url.value
      }
    }

    card {
      width = 2

      query = query.content_security_policy_check
      args = {
        site_url = self.input.site_url.value
      }
    }

    card {
      width = 2

      query = query.x_frame_options_check
      args = {
        site_url = self.input.site_url.value
      }
    }

    card {
      width = 2

      query = query.x_content_type_options_check
      args = {
        site_url = self.input.site_url.value
      }
    }

    card {
      width = 2

      query = query.referrer_policy_check
      args = {
        site_url = self.input.site_url.value
      }
    }

    card {
      width = 2

      query = query.permissions_policy_check
      args = {
        site_url = self.input.site_url.value
      }
    }
  }

  container {
    container {
      table {
        title = "Missing Headers"
        query = query.missing_headers
        args  = {
          site_url = self.input.site_url.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Raw Headers"
        query = query.raw_header_list
        args  = {
          site_url = self.input.site_url.value
        }
      }
    }
  }
}

query "raw_header_list" {
  sql = <<-EOQ
    select
      header.key as "Header",
      (select string_agg(val, ',') from jsonb_array_elements_text(header.value) as val) as "Value"
    from
      net_request,
      jsonb_each(headers) as header
    where
      url = $1;
  EOQ

  param "site_url" {}
}

query "missing_headers" {
  sql = <<-EOQ
    with available_headers as (
      select
        array_agg(header.key)
      from
        net_request,
        jsonb_each(headers) as header
      where
        url = $1
    ),
    missing_headers as (
      select
        element
      from (
        select unnest(array['Strict-Transport-Security','Content-Security-Policy','X-Frame-Options','X-Content-Type-Options','Referrer-Policy','Permissions-Policy'])
        except
        select unnest(array_agg) from available_headers
      ) t (element)
    )
    select
      element as "Header",
      case
        when element = 'Strict-Transport-Security' then 'HTTP Strict Transport Security is an excellent feature to support on your site and strengthens your implementation of TLS by getting the User Agent to enforce the use of HTTPS. Recommended value "Strict-Transport-Security: max-age=31536000; includeSubDomains".'
        when element = 'Content-Security-Policy' then 'Content Security Policy is an effective measure to protect your site from XSS attacks. By whitelisting sources of approved content, you can prevent the browser from loading malicious assets.'
        when element = 'X-Frame-Options' then 'X-Frame-Options tells the browser whether you want to allow your site to be framed or not. By preventing a browser from framing your site you can defend against attacks like clickjacking. Recommended value "X-Frame-Options: SAMEORIGIN".'
        when element = 'X-Content-Type-Options' then 'X-Content-Type-Options stops a browser from trying to MIME-sniff the content type and forces it to stick with the declared content-type. The only valid value for this header is "X-Content-Type-Options: nosniff".'
        when element = 'Referrer-Policy' then 'Referrer Policy is a new header that allows a site to control how much information the browser includes with navigations away from a document and should be set by all sites.'
        when element = 'Permissions-Policy' then 'Permissions Policy is a new header that allows a site to control which features and APIs can be used in the browser.'
      end as "Description"
    from
      missing_headers;
  EOQ

  param "site_url" {}
}

query "strict_transport_security_check" {
  sql = <<-EOQ
    select
      case
        when header_strict_transport_security is not null then 'Present'
        else 'Missing'
      end as value,
      case
        when header_strict_transport_security is not null then 'ok'
        else 'alert'
      end as type,
      'Strict-Transport-Security' as label
    from
      net_request
    where
      url = $1;
  EOQ

  param "site_url" {}
}

query "content_security_policy_check" {
  sql = <<-EOQ
    select
      case
        when header_content_security_policy is not null then 'Present'
        else 'Missing'
      end as value,
      case
        when header_content_security_policy is not null then 'ok'
        else 'alert'
      end as type,
      'Content-Security-Policy' as label
    from
      net_request
    where
      url = $1;
  EOQ

  param "site_url" {}
}

query "x_frame_options_check" {
  sql = <<-EOQ
    select
      case
        when header_x_frame_options is not null then 'Present'
        else 'Missing'
      end as value,
      case
        when header_x_frame_options is not null then 'ok'
        else 'alert'
      end as type,
      'X-Frame-Options' as label
    from
      net_request
    where
      url = $1;
  EOQ

  param "site_url" {}
}

query "x_content_type_options_check" {
  sql = <<-EOQ
    select
      case
        when header_x_content_type_options is not null then 'Present'
        else 'Missing'
      end as value,
      case
        when header_x_content_type_options is not null then 'ok'
        else 'alert'
      end as type,
      'X-Content-Type-Options' as label
    from
      net_request
    where
      url = $1;
  EOQ

  param "site_url" {}
}

query "referrer_policy_check" {
  sql = <<-EOQ
    select
      case
        when header_referrer_policy is not null then 'Present'
        else 'Missing'
      end as value,
      case
        when header_referrer_policy is not null then 'ok'
        else 'alert'
      end as type,
      'Referrer-Policy' as label
    from
      net_request
    where
      url = $1;
  EOQ

  param "site_url" {}
}

query "permissions_policy_check" {
  sql = <<-EOQ
    select
      case
        when header_permissions_policy is not null then 'Present'
        else 'Missing'
      end as value,
      case
        when header_permissions_policy is not null then 'ok'
        else 'alert'
      end as type,
      'Permissions-Policy' as label
    from
      net_request
    where
      url = $1;
  EOQ

  param "site_url" {}
}