{% macro title_case(expr) %}
    array_to_string(
        list_transform(string_split(lower({{ expr }}), ' '), lambda w: upper(w[1]) || w[2:]),
        ' '
    )
{% endmacro %}
