{#
    Use schema names exactly as configured (bronze, silver, gold).
    By default dbt would prefix them with the target schema, e.g. public_silver.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
