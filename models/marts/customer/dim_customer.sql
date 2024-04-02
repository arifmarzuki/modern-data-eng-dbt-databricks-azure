{{
    config(
        materialized = "table",
        file_format = "delta",
        location_root = "/mnt/gold/customers"
    )
}}

with address_snapshot as (
    select
        AddressID,
        AddressLine1,
        AddressLine2,
        City,
        StateProvince,
        CountryRegion,
        PostalCode
    from {{ ref('address_snapshot') }} where dbt_valid_to is null
)

, customeraddress_sanpshot as (
    select
        CustomerId,
        AddressId,
        AddressType
    from {{ ref('customeraddress_snapshot') }} where dbt_valid_to is null
)

, customer_snapshot as (
    select
        CustomerId,
        concat(ifnull(FirstName,' '),' ',ifnull(MiddleName,' '),' ',ifnull(LastName,' ')) as FullName
    from {{ ref('customer_snapshot') }} where dbt_valid_to is null
)

, transformed as (
    select
        row_number() over (order by customer_snapshot.customerid) as customer_sk, --auto-incremental surrogate key
        customer_snapshot.CustomerId,
        customer_snapshot.fullname,
        customeraddress_sanpshot.AddressID,
        customeraddress_sanpshot.AddressType,
        address_snapshot.AddressLine1,
        address_snapshot.City,
        address_snapshot.StateProvince,
        address_snapshot.CountryRegion,
        address_snapshot.PostalCode
    from customer_snapshot
    inner join customeraddress_sanpshot on customer_snapshot.CustomerId = customeraddress_sanpshot.CustomerId
    inner join address_snapshot on customeraddress_sanpshot.AddressID = address_snapshot.AddressID
)
select * 
from transformed