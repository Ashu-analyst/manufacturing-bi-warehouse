{# Title-casing breaks legal suffixes (GmbH -> Gmbh). Put the common ones back. #}
{% macro fix_legal_suffix(expr) %}
    regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace({{ expr }},
        ' Gmbh$', ' GmbH'), ' Ag$', ' AG'), ' Bv$', ' BV'), ' S\.a\.$', ' S.A.'), ' Inc$', ' Inc.')
{% endmacro %}
