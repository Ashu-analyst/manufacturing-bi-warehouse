{% macro normalise_country(col) %}
    case
        when upper(trim({{ col }})) in ('DE', 'GERMANY', 'DEUTSCHLAND') then 'DE'
        when upper(trim({{ col }})) in ('US', 'USA', 'UNITED STATES') then 'US'
        when length(trim({{ col }})) = 2 then upper(trim({{ col }}))
        else 'XX'  -- unknown: surfaced by the accepted_values test, not silently dropped
    end
{% endmacro %}
