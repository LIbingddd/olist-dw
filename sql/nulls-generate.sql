SELECT CONCAT(stmt, IF(rn = cnt, '', ' UNION ALL')) AS stmt
FROM (
  SELECT CONCAT('SELECT ''', table_name, '.', column_name, ''' AS col, ',
                'SUM(', column_name, ' IS NULL) AS n_null, ',
                'SUM(', column_name, ' = '''') AS n_blank, ',
                'COUNT(*) AS total FROM ', table_name) AS stmt,
         ROW_NUMBER() OVER (ORDER BY table_name, ordinal_position) AS rn,
         COUNT(*) OVER () AS cnt
  FROM information_schema.columns
  WHERE table_schema = 'olist'
) x
ORDER BY rn;
