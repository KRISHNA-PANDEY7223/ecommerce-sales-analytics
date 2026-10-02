import duckdb

# Connect to the local DuckDB database file
con = duckdb.connect("data/ecommerce_data.db")

# Drop the incorrectly typed table
con.execute("DROP TABLE IF EXISTS clean_orders")

# Load the parquet file, casting string columns to their proper types
con.execute("""
    CREATE TABLE clean_orders AS 
    SELECT 
        order_id,
        CAST(ordered_at AS TIMESTAMP) AS ordered_at,
        order_status,
        customer_id,
        country_code,
        acquisition_channel,
        customer_segment,
        line_count,
        units,
        CAST(subtotal AS FLOAT) AS subtotal,
        CAST(tax_amount AS FLOAT) AS tax_amount,
        CAST(shipping_amount AS FLOAT) AS shipping_amount,
        CAST(gross_payment AS FLOAT) AS gross_payment,
        CAST(refund_amount AS FLOAT) AS refund_amount,
        CAST(net_revenue AS FLOAT) AS net_revenue
    FROM 'data/ecommerce-sales-v1.0.0-analysis.parquet'
""")

print("Data re-loaded with correct data types!")
con.close()
