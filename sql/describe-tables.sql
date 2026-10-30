SELECT table_name, ordinal_position AS pos, column_name, column_type
FROM information_schema.columns
WHERE table_schema = 'olist'
ORDER BY table_name, ordinal_position;
