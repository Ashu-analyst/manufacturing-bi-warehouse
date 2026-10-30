{# Minimal version of dbt_utils.generate_surrogate_key, so the project has no package dependency. #}
{% macro dbt_utils_surrogate_key(cols) %}
    md5({% for c in cols %}coalesce(cast({{ c }} as varchar), '_null_'){% if not loop.last %} || '|' || {% endif %}{% endfor %})
{% endmacro %}
